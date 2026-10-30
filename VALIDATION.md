# Validation - IQ Trader 0.5.0

Validated locally on Windows x64, 2026-10-30.

- 109 Python tests passed, including existing order-boundary, retry, reconciliation and update-integrity coverage; new protection toggles, research labels, chronological partitions, cloud pre-submit failure, shared-history conflicts, Windows token encryption, and isolated Tk settings-save tests, literal .env parsing and the research worker CLI startup path.
- Supabase SQL executed twice on local PostgreSQL-compatible PGlite. Checks passed for row-level user isolation, anonymous denial, persistent single-device ownership, pending-order handover blocking, and immutable settled results. This is local SQL validation, not a completed connection to the user's hosted project.
- Packaged offline checks passed: SQLite, spawned connector and catalogue/candle callbacks, research schema, Windows DPAPI token round trip, and bundled SQL. No network or order was used by those checks.
- Standalone installer installed 0.5.0 in a separate per-user directory and passed its offline check. Existing journals remain outside the installation. The installed login window was launched.
- Live Supabase authentication and two-computer synchronization require the user's locally entered project details; their verification status will be recorded separately. Training eligibility and profitability have not been established with real collected data.

Mandatory execution protections remain: account/currency validation, current valid data, broker contract availability, sufficient balance, persistent intent before submission, no unresolved/duplicate orders, and verified device ownership when cloud-enabled. REAL automatic orders remain disabled.

Research labels are five-minute candle proxies, not exact broker settlements. Numeric models are experimental and cannot be described as proven profitable. Temporary connectivity failures and broker schema changes remain possible. Installer is unsigned; hashes verify integrity, not independent publisher identity.
