# Laptop resource use

IQ Trader 0.4.0 uses CPU-only rules and bounded logs. It does not need a GPU or a local inference server. The connector runs in an isolated process at reduced priority from the desktop. Read loops yield instead of spinning; candle reads are cached within a minute, and order preflight refreshes contract metadata without downloading candle history again.

Keep one app instance open. Other applications still contribute to system memory pressure. IQ Trader does not uninstall or stop unrelated applications. Temporary network outages are retried; account errors and uncertain orders can still require review.
