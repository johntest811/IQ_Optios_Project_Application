# Version 0.6.0 additions

For shared Windows data, automatic Supabase connection, training, and editable protections, follow [SUPABASE_SETUP.md](SUPABASE_SETUP.md). Supabase SQL is in [supabase/schema.sql](supabase/schema.sql).

# Using IQ Trader 0.4.0

Sign in with PRACTICE selected. Login verifies the account and starts a read-only connection monitor. Select `adaptive` or `baseline` in Strategy, check stake/currency, then Start automatic trading. Leave the app and computer running. The app can wait when there is no setup, a market is closed, a payout is insufficient or a risk limit is reached.

- Running / scanning: checking candidates; no guarantee that an order will qualify.
- Reconnecting / no orders: temporary connection failure; bounded retries are automatic.
- Order awaiting settlement: acknowledged order; no second position will open.
- Waiting / risk limit: inspect the reason; reconnecting does not reset risk history.
- Halted: uncertain submission or repeated non-transient failure; inspect Diagnostics.
- not_sent: a rejected intent, not a broker trade; excluded from trade counts and P&L.

Recover is read-only. The known 0.3.1 expired-signal defect is repaired only when its exact pre-buy error is present in the journal. Timeouts with unknown acceptance are never automatically classified as not sent.

For an installation update, Stop first, open Updates and Check GitHub updates. Confirm installation and reopen using the shortcut. Credentials must be entered again because they are not saved. Local ZIP updates remain available.
