# Shared Windows data and training (0.5.0)

## Connect using .env

After the SQL and Supabase Auth user are ready, use **Shared data & training → Open local .env**. Fill and save:

```dotenv
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR-PUBLISHABLE-OR-ANON-KEY
SUPABASE_EMAIL=YOUR-SUPABASE-AUTH-EMAIL
SUPABASE_PASSWORD=YOUR-SUPABASE-AUTH-PASSWORD
```

The app automatically connects after the file is saved and enables shared data. It stops the broker session before changing the connection; trading remains off. No Connect click or repeated form entry is needed. The default file is `%LOCALAPPDATA%\IQTrader\.env` for the installed app; source runs use the project `.env`. **Use existing .env...** selects a different file without copying it. Only the four Supabase fields (or `SUPABASE_PUBLISHABLE_KEY`) are read; no variable expansion or shell commands are executed.

The publishable key identifies the project; it does not identify the shared user. Supabase Auth email/password are needed for the initial private-data sign-in. On later starts, the app reuses the Windows-encrypted refresh session. You can remove `SUPABASE_EMAIL` and `SUPABASE_PASSWORD` from `.env` after successful sign-in; add them again only if refresh fails. If kept, those two values are plaintext in your local file. `.env` is excluded from Git, installers and source backup. Never share or commit it. Do not copy the entire app data folder between computers; device identity and encrypted sessions must stay local.

Manual connection remains available as an alternative:

1. In your own Supabase project, open **SQL Editor**, paste the full contents of [supabase/schema.sql](supabase/schema.sql), and Run. It is safe to rerun and does not erase data.
2. Under **Authentication → Users**, create an email/password user. Confirm that user (or complete the confirmation email). Use the same Supabase Auth user on each computer. This is a separate login from IQ Option.
3. Install IQ Trader 0.5.0 on each Windows computer. Sign in locally to the same IQ Option PRACTICE account. Click **Stop** and wait for the session to stop.
4. In **Shared data & training**, enter your `https://PROJECT.supabase.co` URL, publishable key (or legacy anon key), and Supabase Auth email/password. Click **Connect Supabase**. Never enter a service-role key, database password, or secret key.
5. In **Protections**, enable **Share data and coordinate trading through Supabase**, then **Apply**. Collection and automatic numeric training are enabled by default; the trained trading filter is OFF by default. Click **Start automatic trading** only on the computer that should trade.

The SQL is also bundled with the installer; **Open Supabase SQL** opens it locally. Setup cannot be completed until you run SQL and sign in to your own project. No Supabase admin credentials are required by the app.

## What is shared

Completed five-minute research samples, their numeric features and observed payout, order history, and training reports are synchronized in bounded batches every minute while the app is signed in. Research samples are deduplicated across devices. Raw one-minute candles are retained locally for 30 days; the reserved `iq_candles` table is not currently uploaded. Synthetic demo prices never enter the shared training set. IQ Option passwords, email addresses, session cookies, and Supabase passwords are never uploaded into the research tables. Account keys are opaque hashes; data is visible only to the signed-in Supabase user through row-level security. People who share that Supabase login can access the same data.

Supabase session tokens are encrypted with Windows DPAPI and are tied to the Windows user. Each new computer must sign in locally; do not copy session files. The public project key is not a service secret. Use a dedicated Supabase project/user for this application.

Settings are shared explicitly: **Publish settings**, then on the other device **Download settings for review**, review the Protections tab, and **Apply** while stopped. Remote settings never start trading automatically. Broker login, stake, strategy selection, and local device identity are not silently overwritten by shared protection settings.

## Moving trading between devices

1. On the old computer, click **Stop**. Wait until all accepted orders settle/reconcile. Monitoring can reconcile without placing new orders; stop it afterward.
2. Click **Release this device and unlink**. This uploads the final journal, refuses release if shared orders are unresolved, and disables shared execution locally.
3. Stop/close the old app. On the new computer, enable shared data and start PRACTICE. It claims ownership and imports shared order history before checking risk limits. Existing losses, cooldowns and daily order counts carry over.

The owner does not expire automatically. This prevents an offline or delayed old computer from resuming alongside a new one. If a device is permanently lost, first verify broker history and ensure the old application cannot run, then resolve ownership administratively in your Supabase project. Do not delete a pending intent simply because it has no broker ID. It may represent an accepted order whose acknowledgement was lost.

Coordination applies only to cloud-enabled 0.5+ copies using the same Supabase project and Auth user. It cannot control older app versions, copies explicitly run without cloud coordination, other Supabase users/projects, or manual broker trades. A cloud outage blocks new cloud-coordinated submissions; known open trades still reconcile with the broker.

## Automatic learning

This is a small logistic-regression research model, **not an LLM**. It uses eight numeric features from completed one-minute candles and labels whether the candle close five minutes later was higher or lower. These labels are **candle proxies**, not actual binary-option fills, strike prices, or broker settlements. Broker expiry alignment and execution delays can produce different outcomes.

Collection creates one prospective sample per market at a five-minute boundary, using the payout observed then. It does not invent historical payouts or train on unfinished outcomes. A contiguous future five-minute candle path is required to mature each label. Markets (including OTC versus regular) and strategy labels are kept separate. Collection occurs during scanning, including when configurable risk limits pause new orders; it does not issue extra broker requests from the background worker. Read-only account monitoring, disconnected periods and time spent waiting for an open trade do not collect additional snapshots.

Default minimum is **600 matured samples per market and strategy**, roughly 50 hours of uninterrupted five-minute observations and often longer in practice. Defaults: at most one training job per hour per market, only when new labels arrive; at most 10,000 recent rows and 20 training epochs. The worker uses below-normal CPU priority and no GPU. Local raw bars have a 30-day retention; matured samples, journals and reports remain until explicitly removed. Supabase storage quotas still apply.

Training splits observations chronologically 60/20/20, purges overlapping five-minute labels at boundaries, fits on the first partition, chooses a threshold using validation only, and reports the untouched test partition. Eligibility requires at least 50 decisions on each later partition, positive payout-adjusted results exceeding the same-period baseline, and a conservative win-rate lower bound above break-even. Repeated experiments and changing markets still mean this is not proof of future profitability.

By default models only produce research reports. **Use eligible trained filter in PRACTICE** is optional: it can veto existing strategy entries, cannot create entries, increase stakes, change risk settings, or trade REAL. Without a recent eligible model, enabling it blocks entries. Models expire after seven days. Each device trains its own validated numeric artifact from its local plus shared samples; uploaded reports are not downloaded and executed as models. Artifacts contain JSON numbers, never pickle or executable code.

## Protections

Stop before applying changes. The daily trade count cap, total drawdown limit, consecutive loss cap, daily gross-loss cap, cooldown, payout filter and technical-error halt can be enabled/disabled and edited. Polling, broker timeout, retry delay, signal freshness and settlement-warning delay are bounded editable fields. The daily loss cap remains OFF by default, as requested. Disabling a limit does not erase its counters or journal history.

Always enforced: correct account/currency, sufficient balance, valid fresh candles, supported open contracts, no duplicate/unresolved orders, STOP, and cloud device ownership when linked. REAL automatic orders remain disabled. The five-minute contract duration and supported product are implementation constraints, not risk toggles. Settlement-warning delay never fabricates a result or unlocks an unresolved order.

Reference: [Supabase row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security), [database function security](https://supabase.com/docs/guides/database/functions), [chronological evaluation](https://scikit-learn.org/stable/modules/cross_validation.html).
