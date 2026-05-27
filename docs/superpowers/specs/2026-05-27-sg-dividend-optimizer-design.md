# SG Dividend Optimizer — Design Spec

**Date:** 2026-05-27
**Status:** Approved for implementation
**Owner:** Daniel Choong

## Goal

A mobile app for Singapore retail investors that, given an SGD capital amount and a risk preference (Conservative / Neutral / Aggressive), recommends an allocation across SGX-listed dividend-paying securities to maximise projected annual dividend income within the chosen risk band, and projects the resulting capital + dividend growth forward over a user-chosen horizon (1/5/10/20 years) with optional DRIP and monthly contributions.

No equivalent exists for SGX today — the wedge is "given my money + risk level, what should I buy."

## Non-goals (v1)

- No financial advice / personalised recommendations. Framed as an **educational simulator**; outputs are illustrations.
- No portfolio tracking of real holdings.
- No live trade execution / broker integration.
- No user accounts, no PII storage, no auth.
- No push notifications / alerts.
- No US, HK, or other-market coverage.

## Regulatory positioning

The app does **not** provide financial advice under the Singapore Financial Advisers Act. Allocations are presented as illustrative output of a transparent, rule-based optimiser the user has parameterised themselves. A persistent disclaimer banner and a long-form disclaimer screen are required on every release. Marketing copy must avoid "recommend," "should buy," "best for you" language; replace with "example," "illustrative," "based on your inputs."

## Architecture

Two repos, glued by one JSON file in object storage.

### Repo 1: `sg-dividend-data` (Python ETL)

Runs daily at 02:00 SGT via GitHub Actions cron. Free for public repos.

```
sg_dividend_data/
├── refresh.py              # entrypoint
├── universe.py             # curated SGX_DIVIDEND_TICKERS (~80–120)
├── sources/
│   ├── yahoo.py            # price, market cap, TTM yield, beta
│   ├── sginvestors.py      # 5y dividend payment history
│   └── sgx.py              # corporate-action JSON (upcoming declared dividends)
├── scoring.py              # per-ticker RiskScore 0..100
├── writer.py               # assembles & writes sg_dividend_universe.json
└── alerts.py               # Telegram alert on failure

tests/
├── fixtures/               # hermetic HTML/JSON fixtures per source
├── test_yahoo.py
├── test_sginvestors.py
├── test_sgx.py
├── test_scoring.py         # known tickers fall in expected bands
└── test_writer.py          # round-trip
```

Output uploaded to a Cloudflare R2 bucket as `sg_dividend_universe.json` (public-read).

#### Risk score (0 = safest, 100 = riskiest)

Weighted sum, capped at 100:

| Component | Weight | Notes |
|---|---|---|
| Sector | 0–45 | Banks 0–5, Utilities 5–15, Telco 10–20, REITs 20–35, Business Trusts 30–45, Distressed/HY 35–45 |
| Market cap | 0–20 | Small-cap (< S$500M) → +20 linearly to 0 at S$5B |
| 5y dividend volatility | 0–25 | Each cut in last 5y → +10, capped at 25; missing history → +10 |
| Payout ratio | 0–25 | <70% → 0; 70–90% → 0–10; 90–100% → 10–20; >100% → 25 |
| 90d price volatility | 0–15 | Realised vol scaled linearly, 10% → 0, 50% → 15 |

Total capped at 100. Sector classification stored as a hardcoded `SECTOR_MAP: Dict[ticker, sector]` in `universe.py` — SGX official taxonomy is too coarse, so we curate. Component values stored alongside the final score in JSON so it's auditable.

#### Output JSON shape

```json
{
  "generated_at": "2026-05-27T18:00:00+08:00",
  "schema_version": 1,
  "universe": [
    {
      "ticker": "D05",
      "name": "DBS Group",
      "price": 42.10,
      "yield_pct": 5.1,
      "score": 18,
      "score_breakdown": {"sector":10,"mcap":0,"div_vol":0,"payout":5,"price_vol":3},
      "sector": "Banks",
      "lot_size": 100,
      "div_history_5y": [1.92, 1.62, 1.44, 1.20, 1.20]
    }
  ]
}
```

`div_history_5y` is most-recent-FY-first. `null` entries are allowed if the ticker IPO'd less than 5y ago; in that case the scoring `div_vol` component charges the +10 "missing history" penalty.

### Repo 2: `sg-dividend-app` (Flutter)

iOS + Android from a single codebase. Stateless: no auth, no backend, no user data persisted server-side. Local storage holds only cached JSON + last-used inputs.

```
lib/
├── main.dart
├── data/
│   ├── universe_repository.dart   # fetch + cache JSON; bundled snapshot fallback
│   └── models.dart                # Universe, Ticker, Allocation, SimulationPoint
├── domain/
│   ├── optimizer.dart             # pure function: (capital, risk, universe) → Allocation
│   └── simulator.dart             # pure function: (Allocation, horizon, drip, monthly) → List<SimulationPoint>
├── ui/
│   ├── splash_screen.dart
│   ├── input_screen.dart
│   ├── result_screen.dart
│   ├── simulator_screen.dart
│   ├── explain_screen.dart
│   └── disclaimer_screen.dart
└── theme.dart

assets/
└── bundled_universe.json         # ships with the app; offline first run
```

**Dependencies:**
- `flutter_riverpod` — state
- `dio` — HTTP for the JSON fetch (with retry + cache)
- `fl_chart` — simulator line chart, allocation pie chart
- `glados` — property-based tests
- `shared_preferences` — last-used inputs

## Optimizer algorithm

Pure Dart function. Input: `capital_sgd: int`, `risk_level: enum{C,N,A}`, `universe: List<Ticker>`.

```
1. risk_band: C → max_score 35; N → max_score 60; A → max_score 100
2. eligible = universe.where(t => t.score ≤ max_score)
3. sorted = eligible.sortBy(yield_pct desc)
4. greedy fill, respecting:
     - max_per_ticker = 25% of capital
     - max_per_sector = 40% of capital
     - min_tickers = 5  (relax to 3 only if capital < S$2000)
5. quantize each weight to whole lots (lot_size from JSON)
6. allocate residual cash to lowest-score eligible ticker
7. compute projected_annual_div = Σ (lots × lot_size × price × yield_pct / 100)
```

### Edge cases

- **Capital < S$500:** show "Try at least S$1,000 to build a diversified basket on SGX board lots." Do not return an allocation.
- **Capital S$500–S$1,000:** relax `min_tickers` to 3, warn that diversification is limited.
- **No eligible tickers (shouldn't happen with any sane universe):** show empty state with disclaimer link.

## Simulator

Pure Dart function. For each year `y = 1..horizon`:

```
income_y = portfolio_value × yield
if DRIP: portfolio_value += income_y
else:    cash_accumulator += income_y
if monthly_contribution: portfolio_value += monthly_contribution × 12

yield assumed constant at portfolio-weighted average. Clearly labelled as an assumption.
```

Returns `List<SimulationPoint>` with `{year, portfolio_value, cumulative_income, total}`.

## UI flow

1. **Splash** — try fetch JSON, fall back to cached, then bundled. < 1s typical.
2. **Input** — capital (SGD), risk (3-way segmented control), horizon (1/5/10/20), DRIP toggle, optional monthly contribution.
3. **Result** — hero: projected annual dividend SGD + weighted yield %. Pie chart by ticker. Table: ticker, name, weight %, lots, S$ allocated, projected annual S$ income.
4. **Simulator** — fl_chart line chart over horizon. Two series: with-DRIP and without-DRIP. Tap any year for breakdown.
5. **Explain** — "Why these stocks?" Lists the risk-band, sector cap, per-ticker score breakdown. Critical for trust and educational positioning.
6. **Disclaimer** — persistent footer banner + dedicated screen. Required on every release.

## Error handling

- **JSON fetch fails:** show stale cache with banner "Data from {date}, refresh failed." Never block the user.
- **JSON parse fails:** fall back to bundled snapshot, telemetry event.
- **Pipeline scrape fails:** job exits non-zero, Telegram alert fires, R2 file unchanged (better stale than corrupt).
- **App offline first run:** bundled snapshot in assets works without network.

## Testing

### Data pipeline (pytest)
- Each scraper has a hermetic fixture (recorded HTML/JSON) — no live network in tests.
- `test_scoring.py` asserts known tickers fall in expected score bands (DBS < 25, a small-cap REIT > 40, etc.).
- `test_writer.py` round-trips JSON.

### App (Flutter test)
- Unit tests for `optimizer.dart` + `simulator.dart`.
- Property tests via `glados`: any output respects constraints, sums to ≤ capital, beats a "100% STI ETF" baseline yield within band.
- Widget tests for the input → result flow.
- Integration test loading bundled snapshot end-to-end.

### Manual gate before each release
- Run pipeline locally, spot-check 10 tickers' scores by eye. No automated way to verify a risk score is "right."

## Cost

- Cloudflare R2: free tier (10 GB / 1M reads per month) is plenty.
- GitHub Actions: free for public repos.
- Domain (optional, only if we promote the JSON publicly): ~S$15/yr.
- Apple Developer Program: S$133/yr (paid by Daniel).
- Google Play Developer: US$25 one-time (paid by Daniel).

Total recurring infra: **~S$0–5/month** until product-market fit.

## Out-of-scope / future work

- v2: user accounts → saved scenarios, push alerts for ex-dividend dates
- v2: portfolio tracker (manual or via broker CSV import)
- v3: backtester ("what would this allocation have done over the last 5 years?")
- v3: tax-aware (foreign withholding tax modelling for Singapore-listed cross-border instruments)
- v3: Android Auto / iOS widget for today's projected dividend tick

## Open items requiring user action

- Cloudflare R2 bucket creation + API token
- GitHub account + public repo (or 2 repos)
- Apple Developer Program registration (S$133/yr)
- Google Play Developer registration (US$25 one-time)
- macOS access for iOS builds (own Mac, friend's, or MacinCloud)
- Telegram bot token for failure alerts (optional, reuse from Polybot)
