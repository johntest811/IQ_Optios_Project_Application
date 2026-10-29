# Validation ? IQ Trader 0.4.0

Validated on Windows x64, 2026-10-29.

- 99 unit/integration-fixture tests passed. Coverage includes pre-permission timeouts, post-permission uncertainty, expired signals, STOP/freshness checks, account isolation, persistent limits, reconnection, delayed settlement, malformed market data, weekend OTC availability, regime classification, chronological evaluation, login-first GUI and update integrity failures.
- Packaged offline self-test passed: SQLite, spawned connector, patched catalogue/candle callbacks. No network or orders in that test.
- Standalone installer successfully installed 0.4.0 in a separate per-user version directory, ran the offline check and updated shortcuts. Existing journals remain outside the installation.
- Executable archive inspected: no retired model client/loader/checker modules are bundled.
- Verified the legacy pre-buy expiry defect against its journal error and original submission ordering. The affected unsent intent was repaired without changing settled trade results or risk history. Unknown timeouts are not repaired this way.
- Adaptive-v1 has fixture tests, not profitable broker-forward evidence. No current release strategy performance claim is made. The offline evaluator is a candle proxy, not a broker-exact backtest.
- Live authenticated 0.4.0 PRACTICE monitoring verified after the user signed in locally. Both the account monitor and user-started adaptive scanner reported connected. The observed startup scan produced regime/availability holds with no new errors. No new adaptive-strategy broker trade was verified in that observation; long-running reliability remains unproven.

Limitations: unofficial connector and broker availability can change; hard account/schema/integrity errors may stop execution. Temporary read failures retry automatically. Uncertain accepted orders require reconciliation. REAL automatic execution is disabled. Unsigned installer; SHA-256 integrity checks do not independently authenticate the publisher.
