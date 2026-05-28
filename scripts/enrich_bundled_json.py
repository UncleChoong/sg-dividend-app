"""Copy the data pipeline's enriched universe.json into the app's bundled fallback.

The pipeline now writes the JSON already enriched (description, industry,
market_cap_sgd), so this script is just a copy + light sanity-check.

Run from repo root: python scripts/enrich_bundled_json.py
"""
from __future__ import annotations
import json
import os
import shutil
from pathlib import Path

SRC = Path("C:/Users/USER/sg-dividend-data/universe.json")
DEST = Path("C:/Users/USER/sg-dividend-app/assets/bundled_universe.json")


def main() -> int:
    if not SRC.exists():
        print(f"ERROR: source not found at {SRC}. Run the data pipeline first:")
        print("  cd C:/Users/USER/sg-dividend-data")
        print("  python -m sg_dividend_data.refresh --dry-run --output universe.json")
        return 1
    data = json.loads(SRC.read_text())
    universe = data.get("universe", [])
    if not universe:
        print("ERROR: source universe is empty.")
        return 1

    # Sanity: confirm every entry has the fields the app expects.
    missing = []
    for entry in universe:
        for f in ("ticker", "name", "sector", "industry", "description",
                  "price", "yield_pct", "score", "score_breakdown"):
            if f not in entry:
                missing.append(f"{entry.get('ticker', '?')}:{f}")
    if missing:
        print(f"ERROR: {len(missing)} missing fields in source. First 5: {missing[:5]}")
        return 1

    DEST.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SRC, DEST)
    print(f"Copied {len(universe)} tickers from {SRC.name} -> {DEST}")
    print(f"  Size: {os.path.getsize(DEST):,} bytes")
    # Quick stat: count by industry
    industries: dict[str, int] = {}
    for e in universe:
        ind = e["industry"]
        industries[ind] = industries.get(ind, 0) + 1
    print("  By industry:")
    for ind, n in sorted(industries.items(), key=lambda x: -x[1]):
        print(f"    {ind}: {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
