# IQ Trader 0.6.1

Windows application for IQ Option PRACTICE trading with CPU-only rules, optional Supabase sharing, and lightweight numeric research training. No language-model service, model downloads or GPU inference is included. Strategies are experimental, not demonstrated profitable. REAL accounts are read-only.

## New in 0.6.1

The cloud session lock waits briefly for a concurrent local worker, and submission failures now report a safe technical category. Unknown submission acknowledgements remain blocked. Broker outages still require the broker connection to recover.

## New in 0.6.0

- Edit or disable configurable risk limits in **Protections**, including the daily trade cap. Changes require Stop and Apply; journal counters are preserved.
- Automatic Supabase anonymous sessions from `.env`: no email/password or Connect form. A generated private sharing key links your devices.
- Read-only monitoring now collects research automatically; training runs when sufficient labels exist.
- Share research samples, trade history, settings and training reports across Windows computers through your own Supabase project. A persistent single-device owner coordinates cloud-enabled execution.
- Collect prospective five-minute candle labels and automatically train small numeric models with chronological validation. The optional PRACTICE filter remains off by default; models cannot create orders or change stakes.
- Follow [SUPABASE_SETUP.md](SUPABASE_SETUP.md) and run [supabase/schema.sql](supabase/schema.sql). Enter connection details locally in **Shared data & training**.

## Install and start

Get `IQTrader-Setup.exe` from https://github.com/johntest811/IQ_Optios_Project_Application/releases/latest . Windows 10/11 x64; Python and the pinned unofficial IQ connector are bundled. The installer is unsigned.

1. Install and open IQ Trader from the Desktop/Start menu.
2. Leave PRACTICE selected and sign in locally. Credentials stay in memory; sign-in starts monitoring only.
3. Choose `adaptive` or `baseline` in Strategy, check the currency, stake and drawdown limit, then click Start automatic trading.
4. Read the market reason and trade journal. `not_sent` means the intent was rejected before broker submission; it is not a loss or an unresolved trade. `open` means the broker acknowledged the order. `submitting` without acknowledgement needs reconciliation.
5. Stop prevents new work; it cannot cancel contracts already accepted by the broker.

From source:

```powershell
.\.venv\Scripts\pythonw.exe launch_gui.py
```

Or double-click `Start-IQ-Trader.cmd`. First-time development setup: `powershell -ExecutionPolicy Bypass -File setup.ps1`.

## Behavior and limits

Adaptive rules select trend continuation with completed five-minute context or range-edge rejection; shock/flat and transitional conditions wait. Baseline uses EMA9/EMA21, RSI14 and ATR. Both read completed one-minute candles and request nominal five-minute turbo binary contracts, not leveraged forex positions. The broker determines the actual expiry. They can trade CALL or PUT; neither strategy guarantees an order every candle or a profit.

The scanner rotates configured markets and checks live product availability and payout. OTC can be used on weekends only when IQ Option reports a supported turbo contract open. Blitz is unsupported; the app does not substitute it. No particular market has been established as profitable. See [STRATEGY_RESEARCH.md](STRATEGY_RESEARCH.md).

Defaults: fixed stake 1 account-currency unit, no daily loss cap, total drawdown budget 10, stop after 3 consecutive losses, at most 10 accepted/pending trades per UTC day, 5-minute cooldown, one unresolved position. Risk limits remain in force after reconnect/restart. A risk pause is shown separately from a connection failure.

## Connection and order handling

Temporary read/connect failures retry with 10?60 second backoff in the desktop configuration. The broker worker is isolated, time-bounded and uses verified TLS. After reconnect, the app verifies the account and reconciles pending trades before scanning.

A parent/worker permission boundary distinguishes failure before any order can be sent from a failure after sending becomes possible. Explicit pre-buy rejections are journaled as `not_sent` and do not disconnect a healthy socket or consume the trade cap. Unknown acknowledgement failures remain blocked rather than risking a duplicate. Known accepted orders with delayed settlement keep checking history; no new order is allowed until settlement is confirmed. Authentication/account/data-integrity errors may still require user action.

## Updates and source backup

In Updates, Stop the session, select Check GitHub updates, then confirm installation of a newer stable version. The app checks the release asset SHA-256 and ZIP manifest, installs to a separate version directory, and runs an offline startup check before switching shortcuts. Restart from the shortcut; trading stays off. A local ZIP can also be selected. Hashes detect corruption, not a compromised publisher; packages are unsigned.

Public application releases: https://github.com/johntest811/IQ_Optios_Project_Application

Private source backup: https://github.com/johntest811/IQ_Optios_Project

User journals/settings remain in `%LOCALAPPDATA%\IQTrader`. Source backup and release packages exclude journals, credentials, user settings and local runtime data.

## Development and evaluation

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
.\.venv\Scripts\python.exe -m pip install -r requirements-build.txt
.\.venv\Scripts\python.exe build_app.py
.\.venv\Scripts\python.exe -m trader.evaluate candles.csv --strategy adaptive --payout 0.86
```

CSV columns: `from,to,open,max,min,close`; timestamps are integer UTC Unix seconds; rows must be contiguous one-minute bars. The evaluator uses past data only, next-minute open as an entry proxy, a five-minute close as exit and fixed payout. It is not an exact IQ Option execution backtest. Test separately on future data, different sessions, regular and OTC markets before drawing conclusions. See [VALIDATION.md](VALIDATION.md) and [RELEASING.md](RELEASING.md).
