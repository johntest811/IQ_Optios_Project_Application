# Automatic shared data and training - IQ Trader 0.6.0

## One-time project setup

1. In your Supabase project, enable **Allow anonymous sign-ins** under **Authentication / Sign In / Providers** (the anonymous sign-in setting).
2. Run the complete [supabase/schema.sql](supabase/schema.sql) in SQL Editor. Rerun this updated script when upgrading from 0.5.0; it preserves existing journals and tables.
3. In the app, select **Shared data & training > Open local .env** and enter only:

```dotenv
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR-PUBLISHABLE-OR-ANON-KEY
```

`SUPABASE_PUBLISHABLE_KEY` is also accepted. Do not use a database password, service-role key or secret key. `SUPABASE_EMAIL` and `SUPABASE_PASSWORD` are no longer read or needed. There are no Supabase login fields or manual Connect button.

Save the file. IQ Trader generates a random `IQTRADER_SYNC_TOKEN` in it, creates an anonymous Supabase session automatically, joins its private workspace, and enables shared sync. It retries connection failures with backoff up to five minutes. The default installed path is `%LOCALAPPDATA%\IQTrader\.env`; source runs use the project `.env`. The **Use existing .env** button selects another local file.

Anonymous sign-in still authenticates a device; it does not expose tables to unauthenticated visitors. A publishable project key alone cannot read or write your workspace. The private sharing token authorizes joining the workspace; treat it as a secret. Only its SHA-256 hash is stored in the workspace table. Session/refresh tokens are encrypted locally using Windows DPAPI. No IQ Option credentials are sent to Supabase.

If your Supabase project requires CAPTCHA on anonymous sign-up, unattended creation of the initial device session will not work with that setting. The app reports the connection failure and does not bypass CAPTCHA. Project administrator settings and SQL cannot be changed with a publishable key.

## Other Windows computers

Install 0.6.0 and copy the same `.env` to `%LOCALAPPDATA%\IQTrader\.env` on each computer. Include the **same generated IQTRADER_SYNC_TOKEN**. Each computer creates its own anonymous session automatically and joins the same private dataset. Do not copy `cloud-profile.json`, encrypted sessions, or the entire app data directory: device identity must remain unique.

Existing 0.5.0 encrypted sessions can be reused without an email/password. The first workspace created from such a session keeps its existing data owner. A device already linked to a workspace cannot silently switch to another workspace. Do not regenerate the sharing token on each device.

`.env`, local profiles and tokens are excluded from source backup and installers. Anyone with both your project details and sharing token can join the workspace; never publish that file. Supabase administrators still control the underlying database.

## What runs automatically

After IQ Option PRACTICE sign-in, the read-only monitor collects validated broker candles with at most one bounded market request per cycle. It never submits an order. The scanner also collects research, including while configurable risk limits pause entries. A separate below-normal-priority CPU worker synchronizes matured samples, journals and training reports and evaluates whether training is due. It needs no LLM, GPU server, or Train button.

Training requires usable data. By default, each market and strategy needs 600 matured five-minute samples (at least about 50 hours of uninterrupted observations, usually longer). It retrains at most once per hour when new labels exist, with at most 10,000 recent rows and 20 epochs. There is no meaningful model to train from an empty dataset or a handful of trades. Collection and training defaults are on; explicit settings in Protections are respected.

The model is a small numeric logistic regression, not an LLM. Its eight features come from completed one-minute candles. Labels compare the candle close five minutes later with the sample's close; the current payout is recorded prospectively. A contiguous future candle path is required. Historical payouts are never fabricated. These are **candle proxies**, not exact broker entry strikes, expiry alignment, or settlements. Synthetic demo data is excluded.

Data is split chronologically 60/20/20 with overlapping five-minute labels purged at the split boundaries. Training uses the first partition, threshold selection uses validation, and test results use the last partition. An optional trained PRACTICE filter requires at least 50 decisions in each later partition, positive payout-adjusted returns exceeding the same-period baseline, and a conservative win-rate bound above break-even. Repeated experiments and changing markets mean this is not evidence of guaranteed profitability.

The trained trading filter remains off by default. If enabled, only a recent eligible local model may veto existing entries; it cannot create orders, change stake, change protections or trade REAL. Without an eligible model it blocks entries. Models expire after seven days. Each device trains from local plus shared samples; uploaded reports are not executed as downloaded models. Artifacts are JSON numbers, never executable code or pickle.

## Shared data and handover

Completed feature/label samples, observed payout, order history and training reports are synchronized in bounded batches, normally each minute. Samples are deduplicated. Raw one-minute bars are kept locally for 30 days; the reserved `iq_candles` cloud table is not uploaded. Matured samples and journals remain durable; your Supabase storage quota still applies.

Only one linked device owns trading for an account at a time. To change devices:

1. Stop the old device. Reconcile/settle any open order using read-only monitoring, then stop monitoring.
2. Select **Release this device**. The final journal is uploaded and unresolved shared orders block release.
3. Close the old app. Start on the new device; it claims ownership and imports shared history before checking risk limits.

Ownership never expires automatically because the broker does not support fencing tokens. If the old computer is permanently lost, ensure it cannot run, verify broker history, and resolve ownership administratively. Never delete an uncertain intent merely because it has no broker ID.

Coordination applies to linked copies with the same project, workspace token and IQ Option account. It cannot control manual broker orders, old apps, or explicitly unlinked copies. Cloud outages block new coordinated submissions; accepted broker orders still reconcile. Supabase configuration never turns an OFF trading session ON.

## Editable protections

Stop, edit Protections, and Apply. You can disable/edit daily trade cap, drawdown limit, loss streak cap, daily gross-loss cap, cooldown, payout filter and technical-error halt. Timing controls are bounded and editable. The daily loss cap remains off by default. Changes do not erase journal counters.

Always enforced: account/currency verification, sufficient balance, valid fresh data, supported open contracts, STOP, no duplicate/unresolved orders, and shared ownership when linked. REAL automatic execution stays disabled. Nominal five-minute expiry is a supported-product constraint, not a risk toggle.

Settings can be published and downloaded for review; downloaded settings never silently start trading or lower another device's protections. IQ Option authentication remains a separate local login because market data requires a broker session.

References: [Supabase anonymous sign-ins](https://supabase.com/docs/guides/auth/auth-anonymous), [row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).
