"""Audit the bundled SGX universe for data-quality issues.

Run from app repo root: python scripts/audit_universe.py

Checks every ticker for:
  1. yield_pct vs computed-from-history mismatch (>40% gap)
  2. yield_pct outside the [0.5%, 20%] sanity band
  3. Currency mismatch — USD-traded SGX names (J36, H78, BS6, etc.) where
     price/market-cap are USD but we display as SGD.
  4. Stale dividend history (most recent year missing despite a reported yield)
  5. Outlier prices (penny stocks under S$0.05)
  6. Sector vs industry mismatch
  7. Missing description / market cap

Prints a per-ticker report and a summary count of issues. Returns non-zero
when any FATAL-class issues are found.
"""
from __future__ import annotations
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Optional

BUNDLED = Path("C:/Users/USER/sg-dividend-app/assets/bundled_universe.json")

# Authoritative source for currency is now the `currency` field on each
# universe entry (populated by yfinance via the data pipeline). This audit
# flags any entry where currency is set to something other than SGD.


def _ttm_yield_from_history(div_history: list, price: float) -> Optional[float]:
    """Compute TTM yield from the most-recent annual dividend ÷ price.

    div_history[0] is the latest full year. If that's None, fall back to
    the most recent non-None value (acknowledges that yfinance occasionally
    misses the current year).
    """
    if price <= 0:
        return None
    for v in div_history:
        if v is not None and v > 0:
            return v / price * 100
    return None


def audit_entry(e: dict) -> list[tuple[str, str]]:
    """Return a list of (severity, message) issues for this ticker."""
    issues: list[tuple[str, str]] = []
    t = e["ticker"]

    price = e.get("price", 0)
    yield_pct = e.get("yield_pct", 0)
    name = e.get("name", "")
    sector = e.get("sector", "")
    industry = e.get("industry", "")
    desc = e.get("description", "")
    mcap = e.get("market_cap_sgd")
    history = e.get("div_history_5y", []) or []

    # 1. Yield vs history consistency.
    computed = _ttm_yield_from_history(history, price)
    if computed is not None and yield_pct > 0:
        ratio = yield_pct / computed if computed > 0 else 0
        if not (0.6 <= ratio <= 1.6):
            issues.append((
                "WARN-yield-mismatch",
                f"yield={yield_pct:.2f}% vs computed-from-history "
                f"{computed:.2f}% (ratio {ratio:.2f})",
            ))
    elif computed is None and yield_pct > 0 and any(v for v in history):
        issues.append((
            "INFO-yield-no-recent",
            f"yield={yield_pct:.2f}% but most-recent dividend missing in history",
        ))

    # 2. Yield sanity band.
    if yield_pct >= 18.0:
        issues.append(("WARN-yield-extreme", f"yield={yield_pct:.2f}% (near cap)"))
    if 0 < yield_pct < 0.5:
        issues.append(("INFO-yield-low", f"yield={yield_pct:.2f}% below dividend-stock threshold"))

    # 3. Currency check — pipeline now drops non-SGD entries at refresh,
    #    so this should never trigger after the fix lands.
    ccy = e.get("currency")
    if ccy and ccy != "SGD":
        issues.append((
            "FATAL-currency",
            f"non-SGD currency leaked through: {ccy!r}",
        ))

    # 4. Stale dividend history — first slot None.
    if yield_pct > 0 and history and history[0] is None:
        valid = [v for v in history if v is not None]
        if not valid:
            issues.append((
                "WARN-no-history",
                f"yield={yield_pct:.2f}% but zero years of dividend history",
            ))
        else:
            issues.append((
                "INFO-history-gap",
                f"current-year dividend missing in history (last valid year present)",
            ))

    # 5. Penny / micro-cap.
    if price < 0.05:
        issues.append((
            "INFO-penny",
            f"price S${price:.4f} — micro-cap or shell company territory",
        ))

    # 6. Sector vs industry.
    valid_industries = {"Banks", "REITs", "Telco", "Utilities",
                        "Industrials", "Consumer", "Business Trusts", "Other"}
    if industry not in valid_industries:
        issues.append((
            "WARN-industry-bucket",
            f"industry={industry!r} not in canonical filter chip set",
        ))

    # 7. Missing description / market cap.
    if not desc:
        issues.append(("INFO-no-description", "empty description field"))
    if mcap is None:
        issues.append(("INFO-no-mcap", "market_cap_sgd is null"))

    # 8. Name == ticker (auto-enrich didn't resolve a name).
    if name == t:
        issues.append(("WARN-no-name", f"name same as ticker code"))

    return issues


def main() -> int:
    data = json.loads(BUNDLED.read_text())
    universe = data["universe"]
    print(f"Auditing {len(universe)} tickers from {BUNDLED.name}\n")

    summary: Counter = Counter()
    per_severity: dict[str, list[tuple[str, str]]] = {}
    for e in universe:
        issues = audit_entry(e)
        for sev, msg in issues:
            summary[sev] += 1
            per_severity.setdefault(sev, []).append((e["ticker"], msg))

    # Print issues grouped by severity (FATAL first).
    order = ["FATAL", "WARN", "INFO"]
    for prefix in order:
        keys = sorted([k for k in per_severity if k.startswith(prefix)])
        for k in keys:
            entries = per_severity[k]
            print(f"=== {k} ({len(entries)}) ===")
            for t, msg in entries:
                print(f"  {t:7} {msg}")
            print()

    print("-" * 60)
    print("Summary:")
    for k in sorted(summary, key=lambda x: (
        0 if x.startswith("FATAL") else 1 if x.startswith("WARN") else 2, x
    )):
        print(f"  {summary[k]:4} {k}")
    fatal = sum(v for k, v in summary.items() if k.startswith("FATAL"))
    print(f"\n  Total FATAL: {fatal}")
    return 1 if fatal else 0


if __name__ == "__main__":
    raise SystemExit(main())
