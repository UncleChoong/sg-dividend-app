# Final Review — SG Dividend Optimizer MVP

**Reviewer:** Claude Code (Sonnet 4.6)
**Date:** 2026-05-27
**Repos:**
- `C:\Users\USER\sg-dividend-data` (Python ETL, 13 tasks done, 31 tests pass)
- `C:\Users\USER\sg-dividend-app` (Flutter app, tasks 1-14 done, Dart uncompiled)

## Summary

Both repos are well-structured with clean separation of concerns, meaningful test coverage, and a consistent implementation of the spec. One scoring bug silently misclassifies declining-dividend companies as safe (critical for a risk-scoring product). One optimizer bug can violate the 25%/40% diversification caps on the residual allocation pass. The Dart code is syntactically clean — no unescaped interpolation, no missing imports, no null-safety violations visible — but cannot be verified without compilation. Security posture is good; all secrets flow through environment variables and GitHub Secrets.

---

## Critical Issues (must fix before any release)

### 1. `div_vol_points` ascending-shortcut bug silently assigns 0 to declining-dividend histories

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\scoring.py`, lines 41–51

The function builds `non_null` from the history list (most-recent-FY-first) and short-circuits with `return 0` when `non_null` is strictly ascending. But a strictly ascending `non_null` means dividends have been _declining_ every year (the array is most-recent-first, so index 0 is the most recent payment). A company that has cut its dividend four times in a row — e.g. `[0.10, 0.12, 0.15, 0.18, 0.20]` — has a strictly ascending `non_null`, triggers the early return, and is scored **0 on div_vol** instead of the correct **25** (four cuts × 10, capped).

Impact: such a company's total risk score is up to 25 points lower than it should be. It can slip into the conservative filter band and appear in portfolios recommended to cautious investors.

The test `test_div_vol_one_cut` in `tests/test_scoring.py` line 29 asserts `div_vol_points([1.0, 1.1, 1.2, 1.3, 1.4]) == 0` with the comment "rising, no cut," but under most-recent-first semantics this history represents four consecutive cuts. The test passes only because the code contains the same misconception.

**Fix:** Remove the ascending shortcut entirely. The cut-detection loop (lines 55–62) is already correct; let it run unconditionally.

---

### 2. Optimizer residual-allocation pass ignores the 25% and 40% caps

**File:** `C:\Users\USER\sg-dividend-app\lib\domain\optimizer.dart`, lines 58–77

The first greedy pass correctly enforces `maxTickerSgd` and `maxSectorSgd`. The residual pass (lines 64–75) computes `extra = (remaining / lotCost).floor()` and adds all extra lots to the lowest-score held ticker with no re-check of either cap.

Concrete failure: with S$10,000, six `Banks` tickers at S$10/lot (S$1,000/lot), the first pass allocates two lots each to two tickers (reaches the 40% sector cap), leaving S$6,000 residual. The residual pass then adds six more lots to the first ticker, bringing it to S$8,000 (80% of capital) and the Banks sector to S$10,000 (100%). Both the 25% per-ticker and 40% per-sector guarantees break.

The optimizer tests do not cover the residual path — the `respects max 25%` and `respects max 40%` tests only use tickers with different sectors / enough diversity that the first pass consumes all capital.

**Fix:** In the residual loop, cap `extra` to respect both `maxTickerSgd - l.sgdAllocated` (per-ticker headroom remaining) and `maxSectorSgd - (sectorSpent[l.ticker.sector] ?? 0)` (per-sector headroom remaining). Add a regression test with a universe that forces residual allocation.

---

### 3. `refresh_all` uploads an empty universe to R2 when all scrapers fail

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\refresh.py`, lines 57–74

Individual ticker failures are caught and logged (lines 61–68). If every single ticker fails, `snapshots` is empty. The code still calls `write_universe(snapshots, output)` and then `upload_to_r2(output)`, overwriting the R2 file with `{"universe": []}`. The app then silently falls back to the bundled snapshot — but the R2 file is now corrupt relative to the spec invariant "R2 file unchanged (better stale than corrupt)."

**Fix:** Add a guard before `upload_to_r2`:
```python
if len(snapshots) < 10:   # or some reasonable minimum
    telegram_alert(f"Aborting upload: only {len(snapshots)} tickers scraped")
    return snapshots
```

---

## Important Issues (should fix before public launch)

### 4. SGinvestors slug map covers only 4 of 31 tickers

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\sources\sginvestors.py`, lines 10–15

`SLUG_OVERRIDES` has entries for `D05`, `O39`, `U11`, `Z74` only. For the other 27 tickers, `fetch_div_history` falls back to `ticker.lower()` (e.g. `a17u`), which is not a valid SGinvestors URL slug. These requests will return 404 or redirect. `refresh.py` silently swallows the error and writes an empty `div_history_5y=[]` for all 27 affected tickers.

Consequence: 27 of 31 tickers get the "missing history" penalty (+10 on `div_vol`), and their payout/vol scores also default to None-penalised values. Scores are systematically inflated for ~87% of the universe.

**Fix:** Populate `SLUG_OVERRIDES` for all 31 tickers by visiting SGinvestors and noting the actual slug for each one. This is a one-time data entry task.

---

### 5. Yahoo `trailingAnnualDividendYield = 0` is treated as missing

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\sources\yahoo.py`, line 79

```python
ttm_yield_pct=float(yld) * 100 if yld and yld < 1 else (float(yld) if yld else None)
```

When `yld = 0` (dividend suspended, e.g. a company that recently cut to zero), `bool(0)` is `False`, so the expression returns `None`. In `refresh.py` line 49, `ttm_yield_pct=yq.ttm_yield_pct or 0.0` recovers this to `0.0`, but the stock then appears in eligible lists with a 0% yield and would sort to the bottom. This is functionally acceptable but a code smell — it should be explicit: `float(yld) if yld is not None else None`.

The same ambiguity exists in `_from_next_data` at line 79 in `yahoo.py`.

---

### 6. `defaultRemoteUrl` placeholder will silently serve stale data if `--dart-define` is omitted

**File:** `C:\Users\USER\sg-dividend-app\lib\data\universe_repository.dart`, line 12

```dart
defaultValue: 'https://CHANGE_ME.r2.dev/sg_dividend_universe.json',
```

Any build that omits `--dart-define=UNIVERSE_URL=...` will hit this URL, fail, and fall back to cached or bundled data without any user-visible error. Once the real R2 URL exists, this default should be set to the actual URL so a plain `flutter build apk` works for development.

---

### 7. `AllocationLine.weightPct` is a dead stub that always returns 0

**File:** `C:\Users\USER\sg-dividend-app\lib\data\models.dart` (plan version, line 343)

The plan's `models.dart` included `double get weightPct => 0; // computed lazily by consumer`. The committed version silently dropped this getter, which is correct — `result_screen.dart` computes the weight inline. But the plan comment implies this was intentional, so confirm the dead code was intentionally removed. No functional issue; just confirming.

Actually inspecting the committed `models.dart`, the `weightPct` getter is absent entirely — the committed code is clean. No action needed.

---

### 8. `div_vol_points` charges the missing-history penalty even for fully-cut histories in the non-ascending path

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\scoring.py`, lines 56–61

When `non_null` is not empty and not ascending, the cut loop and the `len(non_null) < len(history)` missing-penalty both fire. A company with `[0.5, None, None, None, None]` gets +10 (cut, history[0] < history[1]? No — history[1] is None, skip) = 0 from cuts, then +10 missing = 10. A company with `[0.1, 0.2, None, None, None]` (one cut, some missing) gets +10 (cut) +10 (missing) = 20. This double-counts: a cut implies there was data. Whether this is spec-intended is unclear. At minimum, document the intent in a comment.

---

### 9. No test for `optimize()` when zero eligible tickers exist

**File:** `C:\Users\USER\sg-dividend-app\test\domain\optimizer_test.dart`

The optimizer test for `returns empty when capital too small` tests the `< 500` guard. But there is no test for the case where capital is adequate but the entire universe scores above the risk band (e.g. Conservative with only REITs and Business Trusts). The code silently returns an `Allocation` with empty `lines` — the UI shows the "try S$1,000" message, which is misleading since the real reason is no eligible tickers.

**Fix:** Add a test; and in `result_screen.dart`, distinguish "capital too small" (lines empty + `totalCapital == 0`) from "no eligible tickers" (lines empty + eligible universe was checked).

---

### 10. `glados` property-based tests are listed in `pubspec.yaml` but never written

**File:** `C:\Users\USER\sg-dividend-app\pubspec.yaml`, line 22

The spec requires property-based tests via `glados` (e.g. "any output respects constraints, sums to ≤ capital"). `glados` is a dev dependency, but no `*_glados_test.dart` file exists anywhere. The optimizer constraints are only spot-checked with fixed examples. A property test that generates random capital amounts and universes would catch the residual-cap bug (Issue 2) systematically.

---

## Minor / Nice-to-haves

### 11. `theme.dart` dropped the `fontFamily` line silently

**File:** `C:\Users\USER\sg-dividend-app\lib\theme.dart`, line 10

The plan specified `textTheme: base.textTheme.apply(fontFamily: 'SF Pro Display')`. The committed file omits this. "SF Pro Display" is a system font on iOS but not on Android; omitting it just means the OS default font is used everywhere, which is fine. No functional issue, but Android will not match the intended typography.

### 12. `AppTheme` is a static-only class — no dark theme

The spec is silent on dark mode, but `AppTheme.light()` is the only entry point. If Flutter's `MediaQuery.platformBrightness` requests dark mode, the app will use light colours. Not a v1 blocker, but worth a `TODO`.

### 13. `Row(children: const [...])` deprecated pattern in `simulator_screen.dart`

**File:** `C:\Users\USER\sg-dividend-app\lib\ui\simulator_screen.dart`, line 37

```dart
Row(children: const [
  _LegendDot(color: Colors.teal, label: 'With DRIP'),
  ...
```

`_LegendDot` is not `const`-constructable (it has no `const` constructor). Dart will reject `const [_LegendDot(...)]`. This will be a compile error. The fix is to remove the `const` keyword from the list literal.

### 14. `sginvestors.py`: `_extract_dividend` rejects whole-number amounts like `"2"` or `"0"`

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\sources\sginvestors.py`, line 64

`re.fullmatch(r"(\d+\.\d{1,4})", c2)` requires a decimal point. An amount like `"2"` or `"0"` (integer dividends, rare but possible) would not match and would be silently skipped. Extend the pattern to `r"(\d+(?:\.\d{1,4})?)"`.

### 15. `writer.py`: `sort_keys=True` in `json.dumps` reorders score breakdown fields

**File:** `C:\Users\USER\sg-dividend-data\sg_dividend_data\writer.py`, line 32

`sort_keys=True` re-orders the output JSON alphabetically (`div_vol`, `mcap`, `payout`, `price_vol`, `sector`). The spec example shows them in a different order. This has zero functional impact since JSON is key-order-agnostic, but it makes manual spot-checking harder. Consider removing `sort_keys=True`.

### 16. Splash error path has no retry button

**File:** `C:\Users\USER\sg-dividend-app\lib\ui\splash_screen.dart`, lines 22–28

When `universeProvider` errors (which cannot happen in practice since `UniverseRepository.load()` never throws — it always falls back to bundled), the error UI shows a warning with no retry action. The `UniverseRepository` itself is sound, but if this code path is ever reached, the user is stuck. Add a retry button that calls `ref.invalidate(universeProvider)`.

### 17. No minimum-ticker warning surfaced to the user

**File:** `C:\Users\USER\sg-dividend-app\lib\domain\optimizer.dart`, lines 54–56

The spec requires: "Capital S$500–S$1,000: relax `min_tickers` to 3, warn that diversification is limited." The optimizer computes `minBasket` and checks `lines.length < minBasket` but takes no action (the comment says "Caller will see fewer than min — surfaced in UI as a warning"). `result_screen.dart` does not check this condition and shows no warning. The warning message needs to be added to the result screen.

---

## Spec Compliance

### Missing from implementation

- **Minimum-ticker warning on result screen** (spec: "warn that diversification is limited" for S$500–S$2,000). Optimizer computes `minBasket` correctly but the UI never shows the warning. (See Issue 17.)
- **"No eligible tickers" empty state** (spec: "show empty state with disclaimer link"). The current code shows the "try S$1,000" message for both "capital too small" and "no eligible tickers" cases, conflating two distinct conditions. (See Issue 9.)
- **Stale-cache banner** (spec: "show stale cache with banner 'Data from {date}, refresh failed.'" when network fails). The repository silently falls back to cached or bundled data with no visible indicator to the user that the data may be old. `UniverseRepository` could return a `(Universe, DataSource)` pair so the UI can display a banner when the source is cache or bundled.
- **Property-based tests via `glados`** (spec: "property tests via glados"). Dependency is declared but no tests written. (See Issue 10.)
- **`payout_ratio` always `None`** (spec: payout ratio 0–25 scoring component). The `_compute_payout_ratio` stub in `refresh.py` returns `None` unconditionally (MVP stub), so every ticker defaults to the `None` fallback of +10 penalty points. This means the payout component is not actually data-driven at launch. Documented as a TODO but worth flagging explicitly.
- **`price_vol_90d` always `None`** (same issue — `_compute_price_vol_90d` stub). Every ticker takes the `None` fallback of +5 on price_vol. Both stubs are documented TODOs but the scoring spec expects these to be real values.

### Built that wasn't in spec (YAGNI candidates)

- `scoring.py` includes bands for `Industrials`, `Consumer`, `Healthcare`, and `Other` sectors — not mentioned in the spec's sector table. These are needed because `universe.py` includes such tickers, so they are justified additions.
- The `_find_beta` function in `yahoo.py` includes an HTML span fallback for newer Yahoo Finance layouts. This is defensive scraping, not spec-mandated, but sensible.
- The ascending-shortcut optimisation in `div_vol_points` was not in the original plan and introduces the bug in Issue 1.

---

## Strengths

- **Architecture is clean.** The two-repo JSON-over-R2 design is minimal and the right call for an MVP. No over-engineering.
- **Dart models are schema-correct.** `Ticker.fromJson` correctly handles `null` entries in `div_history_5y`, uses `(j['price'] as num).toDouble()` for safe int/double coercion, and the `RiskLevel` switch is exhaustive — no runtime gaps.
- **DRIP arithmetic is correct.** Five compounds in five years (`y = 1..horizonYears`), year-0 point included. The simulator test verifies this precisely.
- **Security posture is good.** All credentials flow through environment variables and GitHub Secrets. No secrets are hardcoded. The Telegram token appears only in `alerts.py` read from `os.environ`.
- **JSON schema consistency between repos.** Field names (`yield_pct`, `div_history_5y`, `score_breakdown.div_vol`) are consistent end-to-end. The Dart `fromJson` would parse production pipeline output correctly.
- **Hermetic tests.** All scraper tests use recorded HTML/JSON fixtures — no live network in CI. The pytest gate blocks R2 upload on test failure.
- **Disclaimer coverage.** Every screen has `DisclaimerBanner` in its `bottomNavigationBar` and routes to `DisclaimerScreen`. Spec requirement fully met.
