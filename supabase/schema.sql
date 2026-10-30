-- IQ Trader 0.6.0. Run in YOUR Supabase project's SQL Editor as project owner.
-- Enable Anonymous Sign-Ins in Supabase Auth. No email/password needed.
-- Never put a service-role key in the desktop application.
-- Re-runnable; does not drop tables or erase existing data.
begin;

create table if not exists public.iq_samples (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  account_key text not null check (account_key ~ '^[a-f0-9]{64}$'),
  sample_key uuid not null,
  symbol text not null check (length(symbol) between 3 and 20),
  signal_end bigint not null check (signal_end between 0 and 4102444800),
  label_end bigint not null check (label_end = signal_end + 300),
  features jsonb not null check (jsonb_typeof(features) = 'array' and jsonb_array_length(features) = 8),
  outcome smallint not null check (outcome in (-1,0,1)),
  payout double precision not null check (payout > 0 and payout <= 1),
  direction text not null check (direction in ('call','put','hold')),
  strategy text not null check (strategy in ('baseline','adaptive')),
  source text not null default 'broker_candle_proxy_v1' check (source = 'broker_candle_proxy_v1'),
  received_at timestamptz not null default now(),
  primary key (user_id, account_key, sample_key)
);
create index if not exists iq_samples_pull on public.iq_samples(user_id,account_key,received_at,sample_key);

create table if not exists public.iq_candles (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  account_key text not null check (account_key ~ '^[a-f0-9]{64}$'),
  symbol text not null check (length(symbol) between 3 and 20),
  start_time bigint not null check (start_time between 0 and 4102444800),
  open double precision not null check (open > 0 and open < 1e12),
  high double precision not null check (high > 0 and high < 1e12),
  low double precision not null check (low > 0 and low < 1e12),
  close double precision not null check (close > 0 and close < 1e12),
  check (low <= least(open,close) and high >= greatest(open,close) and low <= high),
  primary key (user_id,account_key,symbol,start_time)
);

create table if not exists public.iq_trades (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  account_key text not null check (account_key ~ '^[a-f0-9]{64}$'),
  signal_key text not null check (length(signal_key) between 1 and 200),
  symbol text not null check (length(symbol) between 3 and 20),
  direction text not null check (direction in ('call','put')),
  stake double precision not null check (stake > 0 and stake < 1e12),
  payout double precision not null check (payout > 0 and payout <= 1),
  entry double precision not null check (entry > 0 and entry < 1e12),
  created double precision not null check (created between 0 and 4102444800),
  expires double precision not null check (expires >= created and expires < 4102444800),
  status text not null check (status in ('submitting','open','settled','not_sent')),
  broker_id text,
  settled double precision,
  pnl double precision,
  check ((status = 'settled' and pnl is not null and pnl between -stake-0.000001 and stake+0.000001 and settled is not null and settled >= created and broker_id is not null)
      or (status <> 'settled' and pnl is null and settled is null)),
  check (status <> 'open' or broker_id is not null),
  check (status <> 'not_sent' or broker_id is null),
  primary key (user_id,account_key,signal_key)
);
create index if not exists iq_trades_pull on public.iq_trades(user_id,account_key,created,signal_key);

create table if not exists public.iq_training_runs (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  account_key text not null check (account_key ~ '^[a-f0-9]{64}$'),
  run_id uuid not null,
  symbol text not null,
  created_at timestamptz not null default now(),
  artifact jsonb not null check (jsonb_typeof(artifact)='object' and octet_length(artifact::text) <= 65536),
  primary key (user_id,account_key,run_id)
);
create table if not exists public.iq_settings (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  account_key text not null check (account_key ~ '^[a-f0-9]{64}$'),
  settings jsonb not null check (jsonb_typeof(settings)='object' and octet_length(settings::text) <= 20000),
  primary key (user_id,account_key)
);
create table if not exists public.iq_execution_owners (
  user_id uuid not null references auth.users(id) on delete cascade,
  account_key text not null check (account_key ~ '^[a-f0-9]{64}$'),
  device_id uuid not null,
  acquired_at timestamptz not null default now(),
  primary key (user_id,account_key)
);

-- Anonymous sessions receive an automatic identity. A high-entropy workspace
-- capability links devices; the project publishable key alone grants no data.
create table if not exists public.iq_workspaces (
  token_hash bytea primary key,
  owner_id uuid not null unique references auth.users(id) on delete cascade
);
create table if not exists public.iq_workspace_members (
  member_id uuid primary key references auth.users(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade
);
alter table public.iq_workspaces enable row level security;
alter table public.iq_workspace_members enable row level security;
revoke all on public.iq_workspaces,public.iq_workspace_members from public,anon,authenticated;

create or replace function public.iq_data_owner() returns uuid
language sql stable security definer set search_path = '' as $$
  select coalesce((select owner_id from public.iq_workspace_members where member_id=auth.uid()),auth.uid());
$$;
revoke all on function public.iq_data_owner() from public,anon;
grant execute on function public.iq_data_owner() to authenticated;

create or replace function public.iq_join_workspace(p_token text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare member uuid := auth.uid(); owner uuid; existing uuid; digest bytea;
begin
  if member is null or p_token is null or p_token !~ '^[a-f0-9]{64}$' then raise exception 'invalid workspace request'; end if;
  digest := sha256(convert_to(p_token,'UTF8'));
  perform pg_advisory_xact_lock(hashtextextended(member::text,1));
  perform pg_advisory_xact_lock(hashtextextended(encode(digest,'hex'),2));
  select owner_id into owner from public.iq_workspaces where token_hash=digest;
  select owner_id into existing from public.iq_workspace_members where member_id=member;
  if existing is not null then
    if owner is distinct from existing then raise exception 'device already linked to another workspace'; end if;
    return existing;
  end if;
  if owner is null then
    owner := member;
    insert into public.iq_workspaces(token_hash,owner_id) values(digest,owner);
  end if;
  insert into public.iq_workspace_members(member_id,owner_id) values(member,owner);
  return owner;
end $$;
revoke all on function public.iq_join_workspace(text) from public,anon;
grant execute on function public.iq_join_workspace(text) to authenticated;

-- Workspace-scoped access. Devices with the same private workspace token
-- share data. Other anonymous or permanent users cannot access these rows.
do $policy$
declare tab text;
begin
  foreach tab in array array['iq_samples','iq_candles','iq_trades','iq_training_runs','iq_settings','iq_execution_owners'] loop
    execute format('alter table public.%I enable row level security',tab);
    execute format('revoke all on public.%I from anon, authenticated',tab);
    execute format('grant select on public.%I to authenticated',tab);
    execute format('drop policy if exists owner_read on public.%I',tab);
    execute format('create policy owner_read on public.%I for select to authenticated using ((select public.iq_data_owner()) = user_id)',tab);
    if tab <> 'iq_execution_owners' then
      execute format('grant insert on public.%I to authenticated',tab);
      execute format('drop policy if exists owner_insert on public.%I',tab);
      execute format('create policy owner_insert on public.%I for insert to authenticated with check ((select public.iq_data_owner()) = user_id)',tab);
    end if;
    if tab in ('iq_trades','iq_settings') then
      execute format('grant update on public.%I to authenticated',tab);
      execute format('drop policy if exists owner_update on public.%I',tab);
      execute format('create policy owner_update on public.%I for update to authenticated using ((select public.iq_data_owner()) = user_id) with check ((select public.iq_data_owner()) = user_id)',tab);
    end if;
  end loop;
end $policy$;

-- Stale uploads cannot turn a settled trade back into an open trade, change
-- its identity, or overwrite a conflicting settlement.
create or replace function public.iq_trade_transition() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (new.user_id,new.account_key,new.signal_key,new.symbol,new.direction,new.stake,new.payout,new.entry,new.created,new.expires)
     is distinct from (old.user_id,old.account_key,old.signal_key,old.symbol,old.direction,old.stake,old.payout,old.entry,old.created,old.expires) then
    raise exception 'trade identity/terms are immutable';
  end if;
  if old.status in ('settled','not_sent') and new.status not in ('settled','not_sent') then return old; end if;
  if old.status = 'open' and new.status = 'submitting' then return old; end if;
  if old.status in ('settled','not_sent') and (new.status,new.pnl,new.broker_id) is distinct from (old.status,old.pnl,old.broker_id) then
    raise exception 'conflicting final trade state';
  end if;
  if old.broker_id is not null and new.broker_id is distinct from old.broker_id then raise exception 'conflicting broker ID'; end if;
  return new;
end $$;
drop trigger if exists iq_trade_transition on public.iq_trades;
create trigger iq_trade_transition before update on public.iq_trades for each row execute function public.iq_trade_transition();

-- A persistent single-device owner, NOT an expiring lease. IQ Option does not
-- accept fencing tokens, so timeout-based automatic takeover would be unsafe.
create or replace function public.iq_claim_executor(p_account_key text,p_device_id uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
declare uid uuid := public.iq_data_owner(); owner uuid;
begin
  if uid is null or p_account_key !~ '^[a-f0-9]{64}$' or p_device_id is null then raise exception 'invalid authenticated request'; end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text || ':' || p_account_key, 0));
  select device_id into owner from public.iq_execution_owners where user_id=uid and account_key=p_account_key for update;
  if owner is not null then return owner=p_device_id; end if;
  if exists(select 1 from public.iq_trades where user_id=uid and account_key=p_account_key and status in ('submitting','open')) then return false; end if;
  insert into public.iq_execution_owners(user_id,account_key,device_id) values(uid,p_account_key,p_device_id);
  return true;
end $$;
create or replace function public.iq_release_executor(p_account_key text,p_device_id uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
declare uid uuid := public.iq_data_owner(); changed integer;
begin
  if uid is null or p_account_key !~ '^[a-f0-9]{64}$' or p_device_id is null then raise exception 'invalid authenticated request'; end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text || ':' || p_account_key, 0));
  if exists(select 1 from public.iq_trades where user_id=uid and account_key=p_account_key and status in ('submitting','open')) then return false; end if;
  delete from public.iq_execution_owners where user_id=uid and account_key=p_account_key and device_id=p_device_id;
  get diagnostics changed = row_count;
  return changed=1;
end $$;
revoke all on function public.iq_claim_executor(text,uuid) from public,anon;
revoke all on function public.iq_release_executor(text,uuid) from public,anon;
grant execute on function public.iq_claim_executor(text,uuid) to authenticated;
grant execute on function public.iq_release_executor(text,uuid) to authenticated;
revoke all on function public.iq_trade_transition() from public,anon,authenticated;

commit;
