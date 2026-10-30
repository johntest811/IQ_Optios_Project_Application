# Validation - IQ Trader 0.6.1

Windows x64, 2026-10-30.

- 116 Python tests passed, including bounded cloud session-lock contention, timeout behavior, secret-safe failure diagnostics, rejection before broker submission, the immutable journal, ownership, research and model validation.
- A Windows cross-process check confirmed an authentication lock waits for the other process and then acquires the lock. A hosted Supabase diagnostic recorded an isolated synthetic intent as not sent, reconciled it, and released its temporary owner. No broker order was sent by this check.
- IQ Option's HTTPS endpoint timed out from this computer while another public site responded; local DNS agreed with a public resolver. The exact network or broker cause is not established, and the release cannot guarantee reconnect while the broker is unavailable.
- IQ Trader 0.6.0 had successfully synced research and journal rows on this hosted Supabase project; separate sessions were tested for shared access and exclusive ownership. See the 0.6.0 release notes for earlier verification.
- Strategies and numeric proxy models remain experimental. Profitability, long-running uptime and an error-free system are not established. REAL automatic execution is disabled.

Installers are unsigned; SHA-256 checks detect corruption but do not prove publisher identity. Private .env values, tokens and user journals are excluded from releases and source backup.
