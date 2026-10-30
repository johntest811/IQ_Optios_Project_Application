# Validation - IQ Trader 0.6.0

Windows x64, 2026-10-30.

- 114 Python tests passed, including automatic anonymous session reuse, workspace identity checks, sharing-key generation, no-email/password .env parsing, read-only market collection without orders, tolerant broker-journal reconciliation and immutable-term sync, protection controls, order boundaries, reconciliation and update integrity.
- The complete Supabase SQL ran twice on local PostgreSQL-compatible PGlite. Tests cover anonymous-session workspace sharing, cross-workspace read/write isolation, token-table access denial, persistent device ownership, pending-order handover blocking and immutable settled results.
- Hosted Supabase: an automatic anonymous session joined the private workspace; existing PRACTICE journal and research samples uploaded and were read back. A second independent anonymous session joined the same workspace and read the same journal. Live RPC checks verified concurrent ownership was refused and explicit handover succeeded with a temporary test account key. No broker orders were submitted by these checks.
- Trading strategies and trained proxy models remain experimental. Profitable performance and long-running reliability are not established. REAL automatic execution is disabled.

The installer is unsigned. SHA-256 checks detect corruption, not a compromised publisher. No passwords, sharing tokens, account journals or local .env files are included in source backup or release assets.
