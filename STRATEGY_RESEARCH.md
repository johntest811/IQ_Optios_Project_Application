# Strategy evidence and experimental adaptation

Review date: 2026-10-29. No reviewed source establishes a reliably profitable, transferable five-minute strategy for this IQ Option account, quote feed, payout, latency and instruments. Marketing win rates are not validation. There is no claim that these rules are "proven".

IQ Option describes trend following, moving averages, support/resistance, breakouts and RSI divergence as strategy frameworks: https://blog.iqoption.com/en/top-5-options-trading-strategies-every-beginner-should-know/ . It also explains volatility bands: https://blog.iqoption.com/en/bollinger-bands/ . These descriptions are not audited forward results for this implementation.

Sullivan, Timmermann and White discuss selection bias when searching many technical rules: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=160330 . This is a reason to freeze the rules and evaluate on unseen data, not constantly promote whichever variant just won. CFTC describes binary-option payout and fraud risks: https://www.cftc.gov/LearnAndProtect/AdvisoriesAndArticles/fraudadv_binaryoptions.html .

## Implemented experimental rules

`baseline`: existing EMA9/21 alignment, RSI14 directional window, ATR and candle-range filter.

`adaptive-v1`: 20-bar directional efficiency separates trend (>= .35), range (<= .20), and mixed conditions. A trend candidate uses the baseline plus EMA3/6 alignment of completed clock-aligned five-minute groups. In a range, a candle must reject a previous 20-close two-standard-deviation band and close back inside it with direction/RSI confirmation. The latest 14-bar range average relative to the preceding 28 bars rejects expansion above 2x; existing ATR and candle-size bounds also reject shocks/flat data. Thresholds are fixed engineering hypotheses, not optimized or statistically validated parameters.

Adaptation means switching these fixed rule families as the observed regime changes. It does not retrain itself, search parameters, increase stake after losses or infer a guaranteed win probability. Signals/holds and regime reasons are recorded. Default is adaptive in new 0.4.0 configuration; baseline remains selectable for comparison.

## Markets and evaluation

Configured markets are EURUSD, GBPUSD, USDJPY and their configured OTC alternatives plus EURJPY-OTC. Regular/OTC quotes are separate instruments; live catalogue ID and enabled/suspended status are checked. Weekend support depends on live turbo availability, not the calendar alone. Payout must be >= 80%. Neither OTC nor a popular currency pair is inherently a proven edge.

At 86% profit payout, break-even excluding ties is 1/1.86 = 53.76%; at 80% it is 55.56%. Higher advertised payout alone does not establish positive expected value. Evaluate each market/session/regime separately and include losing periods, actual broker entry/expiry and actual payout.

`python -m trader.evaluate candles.csv` produces a chronological candle proxy report with trade counts, net stakes, drawdown, break-even and a Wilson lower bound. The interval assumes independent outcomes; correlated or selected trades violate that assumption. The tool has no broker access. Use a held-out dataset never used for tuning, then a separately observed PRACTICE forward period; this release includes no profitability claim or forward validation of adaptive-v1.
