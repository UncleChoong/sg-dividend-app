# SG Dividend Data Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Python ETL that scrapes Yahoo Finance, SGinvestors.io, and SGX corp-actions, scores each SGX dividend ticker on risk, and emits `sg_dividend_universe.json` to a Cloudflare R2 bucket daily via GitHub Actions.

**Architecture:** Single Python package `sg_dividend_data` with one scraper module per source, a pure-function scoring module, a writer that emits the schema in `docs/superpowers/specs/2026-05-27-sg-dividend-optimizer-design.md`, and a CLI entrypoint `refresh.py` driven by a GitHub Actions cron. All scrapers are tested against hermetic HTML/JSON fixtures — no live network in CI.

**Tech Stack:** Python 3.11, `requests`, `beautifulsoup4`, `pydantic` v2, `pytest`, `boto3` (R2 is S3-compatible), GitHub Actions.

**Repo location:** `C:\Users\USER\sg-dividend-data` (new repo, separate from the Flutter app repo).

---

## File Structure

```
sg-dividend-data/
├── pyproject.toml
├── .gitignore
├── README.md
├── .github/workflows/refresh.yml
├── sg_dividend_data/
│   ├── __init__.py
│   ├── models.py            # TickerSnapshot, UniverseEntry, ScoreBreakdown
│   ├── universe.py          # SGX_DIVIDEND_TICKERS list + SECTOR_MAP dict
│   ├── sources/
│   │   ├── __init__.py
│   │   ├── yahoo.py         # fetch_quote() → price, mcap, ttm_yield, beta
│   │   ├── sginvestors.py   # fetch_div_history() → 5y dividends
│   │   └── sgx.py           # fetch_corp_actions() → upcoming dividends
│   ├── scoring.py           # score(snapshot) → ScoreBreakdown
│   ├── writer.py            # assemble + write sg_dividend_universe.json
│   ├── uploader.py          # upload to Cloudflare R2 via boto3
│   ├── alerts.py            # telegram_alert(error)
│   └── refresh.py           # CLI entrypoint
├── tests/
│   ├── conftest.py
│   ├── fixtures/
│   │   ├── yahoo_d05.html
│   │   ├── sginvestors_d05.html
│   │   └── sgx_corp_actions.json
│   ├── test_models.py
│   ├── test_universe.py
│   ├── test_yahoo.py
│   ├── test_sginvestors.py
│   ├── test_sgx.py
│   ├── test_scoring.py
│   └── test_writer.py
```

---

### Task 1: Project scaffolding

**Files:**
- Create: `C:\Users\USER\sg-dividend-data\pyproject.toml`
- Create: `C:\Users\USER\sg-dividend-data\.gitignore`
- Create: `C:\Users\USER\sg-dividend-data\README.md`
- Create: `C:\Users\USER\sg-dividend-data\sg_dividend_data\__init__.py` (empty)
- Create: `C:\Users\USER\sg-dividend-data\tests\__init__.py` (empty)

- [ ] **Step 1: Create directory + git init**

```bash
mkdir -p /c/Users/USER/sg-dividend-data/sg_dividend_data/sources
mkdir -p /c/Users/USER/sg-dividend-data/tests/fixtures
cd /c/Users/USER/sg-dividend-data
git init -q
```

- [ ] **Step 2: Write pyproject.toml**

```toml
[project]
name = "sg-dividend-data"
version = "0.1.0"
description = "ETL for SGX dividend universe JSON"
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31",
    "beautifulsoup4>=4.12",
    "pydantic>=2.0",
    "boto3>=1.34",
    "python-dateutil>=2.8",
]

[project.optional-dependencies]
dev = ["pytest>=8.0", "pytest-cov>=5.0", "ruff>=0.5"]

[project.scripts]
sg-dividend-refresh = "sg_dividend_data.refresh:main"

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.ruff]
line-length = 100
```

- [ ] **Step 3: Write .gitignore**

```
__pycache__/
*.pyc
.venv/
.pytest_cache/
.ruff_cache/
*.egg-info/
dist/
build/
.env
.coverage
htmlcov/
sg_dividend_universe.json
```

- [ ] **Step 4: Write README.md**

```markdown
# sg-dividend-data

Daily ETL that scrapes SGX dividend stocks and emits `sg_dividend_universe.json` to a Cloudflare R2 bucket. Consumed by the SG Dividend Optimizer mobile app.

## Run locally
```
pip install -e ".[dev]"
sg-dividend-refresh --dry-run     # writes to ./sg_dividend_universe.json
sg-dividend-refresh               # uploads to R2 (requires env vars)
```

## Required env vars
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` (optional, for failure alerts)
```

- [ ] **Step 5: Install + verify**

```bash
cd /c/Users/USER/sg-dividend-data
python -m venv .venv
source .venv/Scripts/activate
pip install -e ".[dev]"
pytest --version
```
Expected: pytest version prints, no errors.

- [ ] **Step 6: Commit**

```bash
git add .
git -c user.name="Daniel Choong" -c user.email="danielchoong5@gmail.com" commit -m "chore: project scaffolding"
```

---

### Task 2: Data models

**Files:**
- Create: `sg_dividend_data/models.py`
- Test: `tests/test_models.py`

- [ ] **Step 1: Write failing test**

`tests/test_models.py`:
```python
from sg_dividend_data.models import TickerSnapshot, ScoreBreakdown, UniverseEntry

def test_ticker_snapshot_roundtrip():
    snap = TickerSnapshot(
        ticker="D05",
        name="DBS Group",
        sector="Banks",
        price=42.10,
        market_cap=1.2e11,
        ttm_yield_pct=5.1,
        lot_size=100,
        div_history_5y=[1.92, 1.62, 1.44, 1.20, 1.20],
        payout_ratio=0.55,
        price_vol_90d=0.18,
    )
    d = snap.model_dump()
    assert d["ticker"] == "D05"
    assert TickerSnapshot.model_validate(d) == snap

def test_score_breakdown_total():
    sb = ScoreBreakdown(sector=10, mcap=0, div_vol=0, payout=5, price_vol=3)
    assert sb.total() == 18

def test_universe_entry_serializes_to_spec_shape():
    snap = TickerSnapshot(
        ticker="D05", name="DBS Group", sector="Banks",
        price=42.10, market_cap=1.2e11, ttm_yield_pct=5.1,
        lot_size=100, div_history_5y=[1.92, 1.62, 1.44, 1.20, 1.20],
        payout_ratio=0.55, price_vol_90d=0.18,
    )
    sb = ScoreBreakdown(sector=10, mcap=0, div_vol=0, payout=5, price_vol=3)
    entry = UniverseEntry.from_snapshot(snap, sb)
    out = entry.model_dump()
    assert out["ticker"] == "D05"
    assert out["score"] == 18
    assert out["score_breakdown"]["sector"] == 10
    assert out["div_history_5y"] == [1.92, 1.62, 1.44, 1.20, 1.20]
```

- [ ] **Step 2: Run test, expect import error**

```bash
pytest tests/test_models.py -v
```
Expected: FAIL — `ModuleNotFoundError: sg_dividend_data.models`

- [ ] **Step 3: Implement models.py**

`sg_dividend_data/models.py`:
```python
from __future__ import annotations
from typing import List, Optional
from pydantic import BaseModel, Field


class TickerSnapshot(BaseModel):
    ticker: str
    name: str
    sector: str
    price: float
    market_cap: float
    ttm_yield_pct: float
    lot_size: int
    div_history_5y: List[Optional[float]] = Field(default_factory=list)
    payout_ratio: Optional[float] = None
    price_vol_90d: Optional[float] = None


class ScoreBreakdown(BaseModel):
    sector: int = 0
    mcap: int = 0
    div_vol: int = 0
    payout: int = 0
    price_vol: int = 0

    def total(self) -> int:
        return min(100, self.sector + self.mcap + self.div_vol + self.payout + self.price_vol)


class UniverseEntry(BaseModel):
    ticker: str
    name: str
    sector: str
    price: float
    yield_pct: float
    score: int
    score_breakdown: ScoreBreakdown
    lot_size: int
    div_history_5y: List[Optional[float]]

    @classmethod
    def from_snapshot(cls, snap: TickerSnapshot, sb: ScoreBreakdown) -> "UniverseEntry":
        return cls(
            ticker=snap.ticker,
            name=snap.name,
            sector=snap.sector,
            price=snap.price,
            yield_pct=snap.ttm_yield_pct,
            score=sb.total(),
            score_breakdown=sb,
            lot_size=snap.lot_size,
            div_history_5y=snap.div_history_5y,
        )
```

- [ ] **Step 4: Run tests, expect pass**

```bash
pytest tests/test_models.py -v
```
Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/models.py tests/test_models.py
git commit -m "feat: data models for ticker snapshots, scores, universe entries"
```

---

### Task 3: Universe + sector map

**Files:**
- Create: `sg_dividend_data/universe.py`
- Test: `tests/test_universe.py`

This is the curated list of SGX dividend tickers we care about, with each one's sector. ~80–120 tickers. The list is hand-curated — it's the only place a human steers what the app considers.

- [ ] **Step 1: Write failing test**

`tests/test_universe.py`:
```python
from sg_dividend_data.universe import SGX_DIVIDEND_TICKERS, SECTOR_MAP, lot_size_for

def test_universe_includes_local_banks():
    for t in ("D05", "O39", "U11"):
        assert t in SGX_DIVIDEND_TICKERS

def test_universe_includes_core_reits():
    for t in ("A17U", "C38U", "M44U", "N2IU", "ME8U"):
        assert t in SGX_DIVIDEND_TICKERS

def test_sector_map_covers_every_ticker():
    missing = [t for t in SGX_DIVIDEND_TICKERS if t not in SECTOR_MAP]
    assert missing == [], f"sector missing for: {missing}"

def test_sectors_are_known():
    allowed = {"Banks", "Utilities", "Telco", "REITs", "Business Trusts", "Industrials",
               "Consumer", "Healthcare", "Other"}
    for t, sec in SECTOR_MAP.items():
        assert sec in allowed, f"{t} has unknown sector {sec}"

def test_lot_size_default_100():
    assert lot_size_for("D05") == 100

def test_lot_size_etfs_can_differ():
    # ES3 (STI ETF) is 100; QL3 also 100 in SGX retail. Just check function returns int.
    assert isinstance(lot_size_for("ES3"), int)
```

- [ ] **Step 2: Run test, expect fail**

```bash
pytest tests/test_universe.py -v
```
Expected: FAIL — module not found.

- [ ] **Step 3: Implement universe.py**

`sg_dividend_data/universe.py`:
```python
"""Curated SGX dividend-paying tickers + sector classification."""
from __future__ import annotations
from typing import Dict, List

# Hand-curated. Add/remove tickers here. Each must also appear in SECTOR_MAP.
SGX_DIVIDEND_TICKERS: List[str] = [
    # Banks
    "D05", "O39", "U11",
    # Utilities / Telco / Infra
    "Z74", "CC3", "AJBU", "CJLU",
    # Core S-REITs
    "A17U", "C38U", "M44U", "N2IU", "ME8U", "T82U", "J69U", "BUOU", "C2PU",
    "AU8U", "M1GU", "ACV", "T39",
    # Healthcare / specialty REITs
    "C2PU", "ME8U",  # dedup ok, set() later
    # Business Trusts / Yield plays
    "U96", "S58",
    # Industrials / Defensives
    "S63", "Y92", "C07", "BN4",
    # Consumer / F&B
    "F34", "S68",  # S68 is SGX itself
    # ETFs (high-yield)
    "ES3", "QL3", "G3B",
]
# Deduplicate while preserving order
SGX_DIVIDEND_TICKERS = list(dict.fromkeys(SGX_DIVIDEND_TICKERS))

SECTOR_MAP: Dict[str, str] = {
    "D05": "Banks", "O39": "Banks", "U11": "Banks",
    "Z74": "Telco", "CC3": "Telco",
    "AJBU": "Utilities", "CJLU": "Utilities",
    "A17U": "REITs", "C38U": "REITs", "M44U": "REITs", "N2IU": "REITs", "ME8U": "REITs",
    "T82U": "REITs", "J69U": "REITs", "BUOU": "REITs", "C2PU": "REITs",
    "AU8U": "REITs", "M1GU": "REITs", "ACV": "REITs", "T39": "REITs",
    "U96": "Business Trusts", "S58": "Business Trusts",
    "S63": "Industrials", "Y92": "Consumer", "C07": "Consumer", "BN4": "Industrials",
    "F34": "Consumer", "S68": "Industrials",
    "ES3": "Other", "QL3": "Other", "G3B": "Other",
}

# Default SGX lot size is 100 shares. Exceptions can be added here.
_LOT_OVERRIDES: Dict[str, int] = {}

def lot_size_for(ticker: str) -> int:
    return _LOT_OVERRIDES.get(ticker, 100)
```

- [ ] **Step 4: Run tests**

```bash
pytest tests/test_universe.py -v
```
Expected: 6 passed.

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/universe.py tests/test_universe.py
git commit -m "feat: curated SGX dividend universe + sector map"
```

---

### Task 4: Yahoo Finance scraper

**Files:**
- Create: `sg_dividend_data/sources/__init__.py` (empty)
- Create: `sg_dividend_data/sources/yahoo.py`
- Create: `tests/fixtures/yahoo_d05.html`
- Test: `tests/test_yahoo.py`

We use Yahoo's `quote/{TICKER}.SI` HTML page. Stable enough for daily polling. If it breaks, the scraper raises and the cron job's failure alert fires.

- [ ] **Step 1: Capture a real fixture**

Manually save the current HTML of `https://finance.yahoo.com/quote/D05.SI/` into `tests/fixtures/yahoo_d05.html`. Use curl or browser save-as. **Do not commit this until step 3** — first see how big it is. If > 1MB, trim to the key sections using a script.

```bash
curl -s -A "Mozilla/5.0" "https://finance.yahoo.com/quote/D05.SI/" > tests/fixtures/yahoo_d05.html
ls -lh tests/fixtures/yahoo_d05.html
```

- [ ] **Step 2: Write failing test**

`tests/test_yahoo.py`:
```python
from pathlib import Path
import pytest
from sg_dividend_data.sources.yahoo import parse_quote_html, YahooQuote

FIXTURE = Path(__file__).parent / "fixtures" / "yahoo_d05.html"

def test_parse_d05():
    html = FIXTURE.read_text(encoding="utf-8")
    q = parse_quote_html(html)
    assert isinstance(q, YahooQuote)
    assert q.price > 0
    assert q.market_cap is None or q.market_cap > 1e9
    assert q.ttm_yield_pct is None or 0 < q.ttm_yield_pct < 25

def test_parse_handles_missing_yield():
    html = "<html><body>no data here</body></html>"
    with pytest.raises(ValueError):
        parse_quote_html(html)
```

- [ ] **Step 3: Run, expect fail**

```bash
pytest tests/test_yahoo.py -v
```
Expected: FAIL — module not found.

- [ ] **Step 4: Implement yahoo.py**

Yahoo embeds data in a `<script>` tag as a JSON blob (`root.App.main` historically; current variants use `__NEXT_DATA__`). Parser must be defensive — try multiple shapes.

`sg_dividend_data/sources/yahoo.py`:
```python
"""Scrape Yahoo Finance quote page for an SGX ticker."""
from __future__ import annotations
import json
import re
from dataclasses import dataclass
from typing import Optional

import requests
from bs4 import BeautifulSoup

UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}


@dataclass
class YahooQuote:
    price: float
    market_cap: Optional[float]
    ttm_yield_pct: Optional[float]
    beta: Optional[float]


def fetch_quote(ticker: str, *, session: Optional[requests.Session] = None) -> YahooQuote:
    s = session or requests.Session()
    url = f"https://finance.yahoo.com/quote/{ticker}.SI/"
    r = s.get(url, headers=UA, timeout=15)
    r.raise_for_status()
    return parse_quote_html(r.text)


def parse_quote_html(html: str) -> YahooQuote:
    # Strategy 1: __NEXT_DATA__ JSON
    soup = BeautifulSoup(html, "html.parser")
    next_data = soup.find("script", id="__NEXT_DATA__")
    if next_data and next_data.string:
        try:
            data = json.loads(next_data.string)
            return _from_next_data(data)
        except (ValueError, KeyError):
            pass

    # Strategy 2: regex sniff visible price + yield from page text
    price = _find_price(html)
    yield_pct = _find_yield(html)
    mcap = _find_market_cap(html)
    beta = _find_beta(html)
    if price is None:
        raise ValueError("yahoo: could not parse price")
    return YahooQuote(price=price, market_cap=mcap, ttm_yield_pct=yield_pct, beta=beta)


def _from_next_data(data: dict) -> YahooQuote:
    # Yahoo's __NEXT_DATA__ has gone through schema changes; do a recursive find.
    def find(node, key):
        if isinstance(node, dict):
            if key in node and isinstance(node[key], (int, float)):
                return node[key]
            for v in node.values():
                r = find(v, key)
                if r is not None:
                    return r
        elif isinstance(node, list):
            for v in node:
                r = find(v, key)
                if r is not None:
                    return r
        return None

    price = find(data, "regularMarketPrice")
    mcap = find(data, "marketCap")
    yld = find(data, "trailingAnnualDividendYield")
    beta = find(data, "beta")
    if price is None:
        raise ValueError("yahoo: regularMarketPrice missing from __NEXT_DATA__")
    return YahooQuote(
        price=float(price),
        market_cap=float(mcap) if mcap else None,
        ttm_yield_pct=float(yld) * 100 if yld and yld < 1 else (float(yld) if yld else None),
        beta=float(beta) if beta else None,
    )


def _find_price(html: str) -> Optional[float]:
    m = re.search(r'"regularMarketPrice":\s*\{?\s*"raw":\s*([0-9.]+)', html)
    if m:
        return float(m.group(1))
    m = re.search(r'"regularMarketPrice":\s*([0-9.]+)', html)
    return float(m.group(1)) if m else None


def _find_yield(html: str) -> Optional[float]:
    m = re.search(r'"trailingAnnualDividendYield":\s*\{?\s*"raw":\s*([0-9.]+)', html)
    if m:
        v = float(m.group(1))
        return v * 100 if v < 1 else v
    return None


def _find_market_cap(html: str) -> Optional[float]:
    m = re.search(r'"marketCap":\s*\{?\s*"raw":\s*([0-9.]+)', html)
    return float(m.group(1)) if m else None


def _find_beta(html: str) -> Optional[float]:
    m = re.search(r'"beta":\s*\{?\s*"raw":\s*(-?[0-9.]+)', html)
    return float(m.group(1)) if m else None
```

- [ ] **Step 5: Run, expect pass**

```bash
pytest tests/test_yahoo.py -v
```
Expected: 2 passed. If the parser can't find price in the fixture, manually inspect the HTML and tighten the regexes/JSON path until it does.

- [ ] **Step 6: Commit**

```bash
git add sg_dividend_data/sources/__init__.py sg_dividend_data/sources/yahoo.py tests/test_yahoo.py tests/fixtures/yahoo_d05.html
git commit -m "feat(sources): Yahoo Finance scraper"
```

---

### Task 5: SGinvestors.io dividend history scraper

**Files:**
- Create: `sg_dividend_data/sources/sginvestors.py`
- Create: `tests/fixtures/sginvestors_d05.html`
- Test: `tests/test_sginvestors.py`

SGinvestors.io has a per-stock dividend history table at e.g. `https://sginvestors.io/sgx/stock/d05-dbs-group/share-dividend-history`.

- [ ] **Step 1: Capture a real fixture**

```bash
curl -s -A "Mozilla/5.0" "https://sginvestors.io/sgx/stock/d05-dbs-group/share-dividend-history" > tests/fixtures/sginvestors_d05.html
ls -lh tests/fixtures/sginvestors_d05.html
```

- [ ] **Step 2: Write failing test**

`tests/test_sginvestors.py`:
```python
from pathlib import Path
from sg_dividend_data.sources.sginvestors import parse_div_history, fetch_div_history

FIXTURE = Path(__file__).parent / "fixtures" / "sginvestors_d05.html"

def test_parse_d05_returns_5y_floats():
    html = FIXTURE.read_text(encoding="utf-8")
    hist = parse_div_history(html)
    assert len(hist) == 5
    for entry in hist:
        assert entry is None or isinstance(entry, float)
    # DBS has paid > S$1 in dividends in recent FYs
    non_null = [e for e in hist if e is not None]
    assert non_null, "expected at least one non-null dividend"
    assert max(non_null) > 0.5

def test_parse_handles_empty_table():
    hist = parse_div_history("<html><body><table></table></body></html>")
    assert hist == [None, None, None, None, None]
```

- [ ] **Step 3: Run, expect fail**

```bash
pytest tests/test_sginvestors.py -v
```
Expected: FAIL.

- [ ] **Step 4: Implement sginvestors.py**

`sg_dividend_data/sources/sginvestors.py`:
```python
"""Scrape SGinvestors.io for 5y dividend history."""
from __future__ import annotations
import re
from typing import List, Optional

import requests
from bs4 import BeautifulSoup

UA = {"User-Agent": "Mozilla/5.0"}
SLUG_OVERRIDES = {
    "D05": "d05-dbs-group",
    "O39": "o39-ocbc-bank",
    "U11": "u11-uob",
    "Z74": "z74-singtel",
    # Add as needed; if missing, scraper raises and operator extends the map.
}


def fetch_div_history(ticker: str, *, session: Optional[requests.Session] = None) -> List[Optional[float]]:
    slug = SLUG_OVERRIDES.get(ticker)
    if not slug:
        # Fallback: try ticker-only slug (sginvestors does sometimes accept this)
        slug = ticker.lower()
    s = session or requests.Session()
    url = f"https://sginvestors.io/sgx/stock/{slug}/share-dividend-history"
    r = s.get(url, headers=UA, timeout=15)
    r.raise_for_status()
    return parse_div_history(r.text)


def parse_div_history(html: str) -> List[Optional[float]]:
    soup = BeautifulSoup(html, "html.parser")
    by_year: dict[int, float] = {}
    # Look for any table with year + dividend columns
    for table in soup.find_all("table"):
        rows = table.find_all("tr")
        for row in rows:
            cells = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cells) < 2:
                continue
            year = _extract_year(cells)
            amt = _extract_dividend(cells)
            if year and amt is not None:
                by_year[year] = by_year.get(year, 0.0) + amt
    if not by_year:
        return [None] * 5
    latest = max(by_year)
    return [by_year.get(latest - i) for i in range(5)]


_YEAR_RE = re.compile(r"\b(20\d{2})\b")


def _extract_year(cells: list[str]) -> Optional[int]:
    for c in cells:
        m = _YEAR_RE.search(c)
        if m:
            return int(m.group(1))
    return None


def _extract_dividend(cells: list[str]) -> Optional[float]:
    # Find a cell that looks like a dividend amount, e.g. "$1.92" or "1.92 SGD"
    for c in cells:
        c2 = c.replace("S$", "").replace("$", "").replace("SGD", "").replace(",", "").strip()
        m = re.fullmatch(r"(\d+\.\d{1,4})", c2)
        if m:
            return float(m.group(1))
    return None
```

- [ ] **Step 5: Run, expect pass**

```bash
pytest tests/test_sginvestors.py -v
```
Expected: 2 passed. Iterate parser if fixture doesn't yield 5y of data.

- [ ] **Step 6: Commit**

```bash
git add sg_dividend_data/sources/sginvestors.py tests/test_sginvestors.py tests/fixtures/sginvestors_d05.html
git commit -m "feat(sources): SGinvestors dividend history scraper"
```

---

### Task 6: SGX corporate actions scraper

**Files:**
- Create: `sg_dividend_data/sources/sgx.py`
- Create: `tests/fixtures/sgx_corp_actions.json`
- Test: `tests/test_sgx.py`

SGX exposes a JSON endpoint at `https://api.sgx.com/securities/v1.1/corporate-actions?...` returning upcoming dividend events. We only use this to flag declared-but-unpaid dividends for the disclaimer copy ("you may receive an additional S$X in the next 3 months") — not for scoring.

- [ ] **Step 1: Capture fixture**

```bash
curl -s "https://api.sgx.com/securities/v1.1/corporate-actions?params=corporate-action,corporate-action-status,corporate-action-type,corporate-action-payment-date,corporate-action-ex-date,corporate-action-record-date,corporate-action-rate&category=DIVIDEND" > tests/fixtures/sgx_corp_actions.json
```

If the live URL fails, write a hand-crafted minimal fixture that matches the documented schema; mark a TODO to refresh once live access is verified.

- [ ] **Step 2: Write failing test**

`tests/test_sgx.py`:
```python
from pathlib import Path
import json
from sg_dividend_data.sources.sgx import parse_corp_actions, upcoming_for

FIXTURE = Path(__file__).parent / "fixtures" / "sgx_corp_actions.json"

def test_parse_returns_list_of_events():
    data = json.loads(FIXTURE.read_text())
    events = parse_corp_actions(data)
    assert isinstance(events, list)
    if events:
        e = events[0]
        assert hasattr(e, "ticker")
        assert hasattr(e, "ex_date")
        assert hasattr(e, "amount")

def test_upcoming_filters_by_ticker():
    data = json.loads(FIXTURE.read_text())
    events = parse_corp_actions(data)
    if events:
        sample = events[0].ticker
        filtered = upcoming_for(sample, events)
        assert all(e.ticker == sample for e in filtered)
```

- [ ] **Step 3: Run, expect fail**

```bash
pytest tests/test_sgx.py -v
```

- [ ] **Step 4: Implement sgx.py**

`sg_dividend_data/sources/sgx.py`:
```python
"""SGX corporate-actions JSON scraper for upcoming declared dividends."""
from __future__ import annotations
from dataclasses import dataclass
from typing import List, Optional
from datetime import date

import requests
from dateutil.parser import parse as dt_parse

UA = {"User-Agent": "Mozilla/5.0"}


@dataclass
class DividendEvent:
    ticker: str
    name: str
    ex_date: Optional[date]
    payment_date: Optional[date]
    amount: Optional[float]


def fetch_corp_actions(*, session: Optional[requests.Session] = None) -> List[DividendEvent]:
    url = "https://api.sgx.com/securities/v1.1/corporate-actions?category=DIVIDEND"
    s = session or requests.Session()
    r = s.get(url, headers=UA, timeout=15)
    r.raise_for_status()
    return parse_corp_actions(r.json())


def parse_corp_actions(data: dict) -> List[DividendEvent]:
    raw = data.get("data") or data.get("items") or []
    out: list[DividendEvent] = []
    for row in raw:
        ticker = (row.get("stock-code") or row.get("ticker") or "").strip()
        name = (row.get("name") or row.get("stock-name") or "").strip()
        ex = _maybe_date(row.get("ex-date") or row.get("corporate-action-ex-date"))
        pay = _maybe_date(row.get("payment-date") or row.get("corporate-action-payment-date"))
        amt = _maybe_float(row.get("rate") or row.get("corporate-action-rate"))
        if ticker:
            out.append(DividendEvent(ticker=ticker, name=name, ex_date=ex, payment_date=pay, amount=amt))
    return out


def upcoming_for(ticker: str, events: List[DividendEvent]) -> List[DividendEvent]:
    today = date.today()
    return [e for e in events if e.ticker == ticker and (e.ex_date is None or e.ex_date >= today)]


def _maybe_date(s) -> Optional[date]:
    if not s:
        return None
    try:
        return dt_parse(str(s)).date()
    except (ValueError, TypeError):
        return None


def _maybe_float(s) -> Optional[float]:
    if s in (None, "", "-"):
        return None
    try:
        return float(s)
    except (ValueError, TypeError):
        return None
```

- [ ] **Step 5: Run, expect pass**

```bash
pytest tests/test_sgx.py -v
```

- [ ] **Step 6: Commit**

```bash
git add sg_dividend_data/sources/sgx.py tests/test_sgx.py tests/fixtures/sgx_corp_actions.json
git commit -m "feat(sources): SGX corporate-actions scraper"
```

---

### Task 7: Scoring module

**Files:**
- Create: `sg_dividend_data/scoring.py`
- Test: `tests/test_scoring.py`

Pure function. Each component is independently tested.

- [ ] **Step 1: Write failing tests**

`tests/test_scoring.py`:
```python
from sg_dividend_data.scoring import score, sector_points, mcap_points, div_vol_points, payout_points, price_vol_points
from sg_dividend_data.models import TickerSnapshot, ScoreBreakdown


def make_snap(**overrides):
    base = dict(
        ticker="X", name="X", sector="Banks", price=10.0, market_cap=5e9,
        ttm_yield_pct=4.0, lot_size=100, div_history_5y=[0.5]*5,
        payout_ratio=0.6, price_vol_90d=0.15,
    )
    base.update(overrides)
    return TickerSnapshot(**base)

def test_sector_points_banks_low():
    assert sector_points("Banks") <= 5

def test_sector_points_business_trusts_high():
    assert sector_points("Business Trusts") >= 30

def test_mcap_small_cap_penalty():
    assert mcap_points(2e8) == 20
    assert mcap_points(1e10) == 0
    assert 0 < mcap_points(1e9) < 20

def test_div_vol_no_cuts():
    assert div_vol_points([1.0, 1.0, 1.0, 1.0, 1.0]) == 0

def test_div_vol_one_cut():
    assert div_vol_points([1.0, 1.1, 1.2, 1.3, 1.4]) == 0  # rising, no cut
    assert div_vol_points([0.5, 1.0, 1.0, 1.0, 1.0]) == 10  # most-recent < next-most-recent

def test_div_vol_missing_history():
    assert div_vol_points([None, None, None, None, None]) == 10

def test_payout_band():
    assert payout_points(0.5) == 0
    assert 0 < payout_points(0.8) < 15
    assert payout_points(1.1) == 25

def test_price_vol_scaling():
    assert price_vol_points(0.10) == 0
    assert price_vol_points(0.50) == 15
    assert 0 < price_vol_points(0.30) < 15

def test_dbs_like_low_score():
    snap = make_snap(sector="Banks", market_cap=1e11, div_history_5y=[1.92,1.62,1.44,1.20,1.20],
                     payout_ratio=0.55, price_vol_90d=0.18)
    sb = score(snap)
    assert sb.total() < 25

def test_distressed_high_yield_high_score():
    snap = make_snap(sector="Business Trusts", market_cap=3e8,
                     div_history_5y=[0.05, 0.02, 0.01, None, None],
                     payout_ratio=1.2, price_vol_90d=0.55)
    sb = score(snap)
    assert sb.total() >= 70
```

- [ ] **Step 2: Run, expect fail**

```bash
pytest tests/test_scoring.py -v
```

- [ ] **Step 3: Implement scoring.py**

`sg_dividend_data/scoring.py`:
```python
"""Risk scoring (0=safe, 100=risky) for SGX dividend tickers."""
from __future__ import annotations
from typing import List, Optional

from sg_dividend_data.models import TickerSnapshot, ScoreBreakdown

_SECTOR_BAND = {
    "Banks": (0, 5),
    "Utilities": (5, 15),
    "Telco": (10, 20),
    "REITs": (20, 35),
    "Business Trusts": (30, 45),
    "Industrials": (10, 25),
    "Consumer": (15, 30),
    "Healthcare": (15, 30),
    "Other": (15, 30),
}


def sector_points(sector: str) -> int:
    lo, hi = _SECTOR_BAND.get(sector, (15, 30))
    return (lo + hi) // 2


def mcap_points(market_cap: Optional[float]) -> int:
    if market_cap is None:
        return 20
    if market_cap <= 5e8:
        return 20
    if market_cap >= 5e9:
        return 0
    # linear between 5e8 and 5e9
    pct = (5e9 - market_cap) / (5e9 - 5e8)
    return int(round(20 * pct))


def div_vol_points(history: List[Optional[float]]) -> int:
    non_null = [h for h in history if h is not None]
    if not non_null:
        return 10
    pts = 0
    # Count cuts: any year where dividend < previous (older) year
    for i in range(len(history) - 1):
        cur = history[i]
        prev = history[i + 1]
        if cur is not None and prev is not None and cur < prev:
            pts += 10
    if len(non_null) < 5:
        pts += 10  # missing-history penalty
    return min(25, pts)


def payout_points(ratio: Optional[float]) -> int:
    if ratio is None:
        return 10
    if ratio < 0.7:
        return 0
    if ratio < 0.9:
        return int(round(10 * (ratio - 0.7) / 0.2))
    if ratio < 1.0:
        return int(round(10 + 10 * (ratio - 0.9) / 0.1))
    return 25


def price_vol_points(vol: Optional[float]) -> int:
    if vol is None:
        return 5
    if vol <= 0.10:
        return 0
    if vol >= 0.50:
        return 15
    return int(round(15 * (vol - 0.10) / 0.40))


def score(snap: TickerSnapshot) -> ScoreBreakdown:
    return ScoreBreakdown(
        sector=sector_points(snap.sector),
        mcap=mcap_points(snap.market_cap),
        div_vol=div_vol_points(snap.div_history_5y),
        payout=payout_points(snap.payout_ratio),
        price_vol=price_vol_points(snap.price_vol_90d),
    )
```

- [ ] **Step 4: Run, expect pass**

```bash
pytest tests/test_scoring.py -v
```
Expected: 11 passed.

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/scoring.py tests/test_scoring.py
git commit -m "feat: risk scoring engine"
```

---

### Task 8: Writer (JSON assembly)

**Files:**
- Create: `sg_dividend_data/writer.py`
- Test: `tests/test_writer.py`

- [ ] **Step 1: Write failing test**

`tests/test_writer.py`:
```python
import json
from pathlib import Path
from sg_dividend_data.writer import assemble, write_universe
from sg_dividend_data.models import TickerSnapshot

def make_snap(ticker="D05", sector="Banks", **kw):
    base = dict(ticker=ticker, name=f"{ticker} Inc", sector=sector,
                price=10.0, market_cap=5e9, ttm_yield_pct=4.0, lot_size=100,
                div_history_5y=[0.4]*5, payout_ratio=0.5, price_vol_90d=0.15)
    base.update(kw)
    return TickerSnapshot(**base)


def test_assemble_produces_universe():
    snaps = [make_snap("D05"), make_snap("A17U", sector="REITs")]
    out = assemble(snaps)
    assert "generated_at" in out
    assert out["schema_version"] == 1
    assert len(out["universe"]) == 2
    tickers = {e["ticker"] for e in out["universe"]}
    assert tickers == {"D05", "A17U"}


def test_write_universe_round_trips(tmp_path: Path):
    snaps = [make_snap("D05")]
    path = tmp_path / "out.json"
    write_universe(snaps, path)
    data = json.loads(path.read_text())
    assert data["universe"][0]["ticker"] == "D05"
    assert "score" in data["universe"][0]
    assert "score_breakdown" in data["universe"][0]
```

- [ ] **Step 2: Run, expect fail**

```bash
pytest tests/test_writer.py -v
```

- [ ] **Step 3: Implement writer.py**

`sg_dividend_data/writer.py`:
```python
"""Assemble snapshots → final JSON universe and write to disk."""
from __future__ import annotations
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import List

from sg_dividend_data.models import TickerSnapshot, UniverseEntry
from sg_dividend_data.scoring import score

SGT = timezone(timedelta(hours=8))
SCHEMA_VERSION = 1


def assemble(snapshots: List[TickerSnapshot]) -> dict:
    entries = []
    for snap in snapshots:
        sb = score(snap)
        entry = UniverseEntry.from_snapshot(snap, sb)
        entries.append(entry.model_dump())
    return {
        "generated_at": datetime.now(SGT).isoformat(),
        "schema_version": SCHEMA_VERSION,
        "universe": entries,
    }


def write_universe(snapshots: List[TickerSnapshot], path: Path) -> Path:
    data = assemble(snapshots)
    path = Path(path)
    path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
    return path
```

- [ ] **Step 4: Run, expect pass**

```bash
pytest tests/test_writer.py -v
```

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/writer.py tests/test_writer.py
git commit -m "feat: writer assembles snapshots into universe JSON"
```

---

### Task 9: Telegram alerts

**Files:**
- Create: `sg_dividend_data/alerts.py`
- Test: `tests/test_alerts.py`

- [ ] **Step 1: Write failing test**

`tests/test_alerts.py`:
```python
from unittest.mock import patch, MagicMock
from sg_dividend_data.alerts import telegram_alert

def test_telegram_alert_skips_when_no_token(monkeypatch):
    monkeypatch.delenv("TELEGRAM_BOT_TOKEN", raising=False)
    assert telegram_alert("hello") is False

def test_telegram_alert_posts_when_configured(monkeypatch):
    monkeypatch.setenv("TELEGRAM_BOT_TOKEN", "abc")
    monkeypatch.setenv("TELEGRAM_CHAT_ID", "123")
    with patch("sg_dividend_data.alerts.requests.post") as p:
        p.return_value = MagicMock(status_code=200)
        ok = telegram_alert("hello")
    assert ok is True
    p.assert_called_once()
    url = p.call_args[0][0]
    assert "abc" in url
    assert p.call_args[1]["data"]["chat_id"] == "123"
```

- [ ] **Step 2: Run, expect fail**

```bash
pytest tests/test_alerts.py -v
```

- [ ] **Step 3: Implement alerts.py**

`sg_dividend_data/alerts.py`:
```python
"""Telegram failure alerts. No-op if env vars missing."""
from __future__ import annotations
import os
import requests


def telegram_alert(message: str) -> bool:
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat = os.environ.get("TELEGRAM_CHAT_ID")
    if not token or not chat:
        return False
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    try:
        r = requests.post(url, data={"chat_id": chat, "text": message[:4000]}, timeout=10)
        return r.status_code == 200
    except requests.RequestException:
        return False
```

- [ ] **Step 4: Run, expect pass**

```bash
pytest tests/test_alerts.py -v
```

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/alerts.py tests/test_alerts.py
git commit -m "feat: telegram failure alerts"
```

---

### Task 10: R2 uploader

**Files:**
- Create: `sg_dividend_data/uploader.py`
- Test: `tests/test_uploader.py`

Cloudflare R2 is S3-API compatible. Use `boto3` with an R2 endpoint URL.

- [ ] **Step 1: Write failing test**

`tests/test_uploader.py`:
```python
from unittest.mock import patch, MagicMock
from sg_dividend_data.uploader import upload_to_r2

def test_upload_to_r2_calls_boto(monkeypatch, tmp_path):
    monkeypatch.setenv("R2_ACCOUNT_ID", "acct")
    monkeypatch.setenv("R2_ACCESS_KEY_ID", "k")
    monkeypatch.setenv("R2_SECRET_ACCESS_KEY", "s")
    monkeypatch.setenv("R2_BUCKET", "bkt")
    f = tmp_path / "u.json"
    f.write_text("{}")
    with patch("sg_dividend_data.uploader.boto3.client") as cli:
        s3 = MagicMock()
        cli.return_value = s3
        upload_to_r2(f, key="sg_dividend_universe.json")
    cli.assert_called_once()
    s3.upload_file.assert_called_once_with(str(f), "bkt", "sg_dividend_universe.json",
                                            ExtraArgs={"ContentType": "application/json",
                                                       "CacheControl": "public, max-age=300"})
```

- [ ] **Step 2: Run, expect fail**

```bash
pytest tests/test_uploader.py -v
```

- [ ] **Step 3: Implement uploader.py**

`sg_dividend_data/uploader.py`:
```python
"""Upload the universe JSON to Cloudflare R2 (S3-compatible)."""
from __future__ import annotations
import os
from pathlib import Path

import boto3


def upload_to_r2(path: Path, *, key: str = "sg_dividend_universe.json") -> None:
    account = os.environ["R2_ACCOUNT_ID"]
    bucket = os.environ["R2_BUCKET"]
    s3 = boto3.client(
        "s3",
        endpoint_url=f"https://{account}.r2.cloudflarestorage.com",
        aws_access_key_id=os.environ["R2_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["R2_SECRET_ACCESS_KEY"],
        region_name="auto",
    )
    s3.upload_file(
        str(path), bucket, key,
        ExtraArgs={"ContentType": "application/json", "CacheControl": "public, max-age=300"},
    )
```

- [ ] **Step 4: Run, expect pass**

```bash
pytest tests/test_uploader.py -v
```

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/uploader.py tests/test_uploader.py
git commit -m "feat: Cloudflare R2 uploader"
```

---

### Task 11: Refresh CLI entrypoint

**Files:**
- Create: `sg_dividend_data/refresh.py`
- Test: `tests/test_refresh.py`

Orchestrates: pull every ticker → snapshot → write → upload → alert on failure.

- [ ] **Step 1: Write failing test**

`tests/test_refresh.py`:
```python
from unittest.mock import patch, MagicMock
from sg_dividend_data.refresh import build_snapshot
from sg_dividend_data.sources.yahoo import YahooQuote


def test_build_snapshot_assembles_fields(monkeypatch):
    yq = YahooQuote(price=42.0, market_cap=1e11, ttm_yield_pct=5.0, beta=1.0)
    monkeypatch.setattr("sg_dividend_data.refresh.fetch_quote", lambda t, session=None: yq)
    monkeypatch.setattr("sg_dividend_data.refresh.fetch_div_history",
                        lambda t, session=None: [1.9, 1.6, 1.4, 1.2, 1.2])
    monkeypatch.setattr("sg_dividend_data.refresh._compute_payout_ratio", lambda *a, **k: 0.5)
    monkeypatch.setattr("sg_dividend_data.refresh._compute_price_vol_90d", lambda *a, **k: 0.18)

    snap = build_snapshot("D05")
    assert snap.ticker == "D05"
    assert snap.sector == "Banks"
    assert snap.price == 42.0
    assert snap.ttm_yield_pct == 5.0
    assert snap.div_history_5y == [1.9, 1.6, 1.4, 1.2, 1.2]
```

- [ ] **Step 2: Run, expect fail**

```bash
pytest tests/test_refresh.py -v
```

- [ ] **Step 3: Implement refresh.py**

`sg_dividend_data/refresh.py`:
```python
"""Refresh the SG dividend universe and upload to R2."""
from __future__ import annotations
import argparse
import logging
import sys
import traceback
from pathlib import Path
from typing import List, Optional

import requests

from sg_dividend_data.alerts import telegram_alert
from sg_dividend_data.models import TickerSnapshot
from sg_dividend_data.sources.sginvestors import fetch_div_history
from sg_dividend_data.sources.yahoo import fetch_quote
from sg_dividend_data.universe import SECTOR_MAP, SGX_DIVIDEND_TICKERS, lot_size_for
from sg_dividend_data.uploader import upload_to_r2
from sg_dividend_data.writer import write_universe

log = logging.getLogger("refresh")


def _compute_payout_ratio(history: list, snapshot=None) -> Optional[float]:
    # MVP: we don't have EPS scraping yet; return None → scoring uses fallback.
    # TODO(v2): pull EPS from Yahoo and compute payout = last_div / eps
    return None


def _compute_price_vol_90d(ticker: str, *, session=None) -> Optional[float]:
    # MVP: stub. Yahoo's chart endpoint gives 90d daily closes; compute stdev/mean.
    # TODO(v2): implement via https://query1.finance.yahoo.com/v8/finance/chart/{T}.SI
    return None


def build_snapshot(ticker: str, *, session: Optional[requests.Session] = None) -> TickerSnapshot:
    yq = fetch_quote(ticker, session=session)
    hist = fetch_div_history(ticker, session=session)
    name = ticker  # MVP — Yahoo's longName isn't always reliable; ticker is fine for display
    return TickerSnapshot(
        ticker=ticker,
        name=name,
        sector=SECTOR_MAP.get(ticker, "Other"),
        price=yq.price,
        market_cap=yq.market_cap or 0.0,
        ttm_yield_pct=yq.ttm_yield_pct or 0.0,
        lot_size=lot_size_for(ticker),
        div_history_5y=hist,
        payout_ratio=_compute_payout_ratio(hist),
        price_vol_90d=_compute_price_vol_90d(ticker, session=session),
    )


def refresh_all(*, dry_run: bool, output: Path) -> List[TickerSnapshot]:
    session = requests.Session()
    snapshots: list[TickerSnapshot] = []
    failures: list[str] = []
    for t in SGX_DIVIDEND_TICKERS:
        try:
            snap = build_snapshot(t, session=session)
            snapshots.append(snap)
            log.info("ok %s price=%.2f yield=%.2f%%", t, snap.price, snap.ttm_yield_pct)
        except Exception as exc:
            log.exception("fail %s: %s", t, exc)
            failures.append(f"{t}: {exc}")
    write_universe(snapshots, output)
    if not dry_run:
        upload_to_r2(output)
    if failures:
        telegram_alert(f"SG dividend refresh: {len(failures)} failures\n" + "\n".join(failures[:20]))
    return snapshots


def main(argv: Optional[list[str]] = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true", help="write JSON locally, do not upload")
    p.add_argument("--output", default="sg_dividend_universe.json")
    args = p.parse_args(argv)
    try:
        snaps = refresh_all(dry_run=args.dry_run, output=Path(args.output))
        log.info("refresh complete: %d tickers", len(snaps))
        return 0
    except Exception:
        tb = traceback.format_exc()
        telegram_alert(f"SG dividend refresh CRASH:\n{tb[-3000:]}")
        log.error("crash:\n%s", tb)
        return 1


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run, expect pass**

```bash
pytest tests/test_refresh.py -v
```

- [ ] **Step 5: Commit**

```bash
git add sg_dividend_data/refresh.py tests/test_refresh.py
git commit -m "feat: refresh CLI entrypoint"
```

---

### Task 12: GitHub Actions workflow

**Files:**
- Create: `.github/workflows/refresh.yml`

- [ ] **Step 1: Write workflow file**

`.github/workflows/refresh.yml`:
```yaml
name: refresh-universe

on:
  schedule:
    - cron: "0 18 * * *"   # 02:00 SGT = 18:00 UTC prev day
  workflow_dispatch:

jobs:
  refresh:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install -e ".[dev]"
      - run: pytest -q
      - name: Refresh universe
        env:
          R2_ACCOUNT_ID:        ${{ secrets.R2_ACCOUNT_ID }}
          R2_ACCESS_KEY_ID:     ${{ secrets.R2_ACCESS_KEY_ID }}
          R2_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
          R2_BUCKET:            ${{ secrets.R2_BUCKET }}
          TELEGRAM_BOT_TOKEN:   ${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID:     ${{ secrets.TELEGRAM_CHAT_ID }}
        run: python -m sg_dividend_data.refresh
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/refresh.yml
git commit -m "ci: daily refresh workflow"
```

- [ ] **Step 3: Manual handoff to user**

After this task, Daniel must:
1. Push the repo to GitHub (`gh repo create sg-dividend-data --public --source . --push`)
2. Add the six secrets in repo Settings → Secrets and variables → Actions
3. Trigger `workflow_dispatch` once to verify the cron job succeeds end-to-end
4. Spot-check the resulting JSON in R2

---

### Task 13: End-to-end smoke test (manual)

- [ ] **Step 1: Run locally with dry-run**

```bash
cd /c/Users/USER/sg-dividend-data
sg-dividend-refresh --dry-run
```
Expected: writes `sg_dividend_universe.json` to current directory. Inspect: every ticker in `SGX_DIVIDEND_TICKERS` should appear unless its scraper failed.

- [ ] **Step 2: Sanity-check 10 tickers by eye**

Compare the JSON's `score`, `yield_pct`, and `price` against the live page on Yahoo / SGinvestors for these 10 tickers:
D05, O39, U11, Z74, A17U, C38U, S63, S68, ES3, QL3.

Allowed deviations:
- Price within 1% of live page
- Yield within 0.5 percentage points
- Score within ±5 of your gut expectation

If any score is wildly off (e.g. DBS scoring > 40), open `scoring.py`, identify which component is wrong, write a regression test against a hand-built snapshot, and fix.

- [ ] **Step 3: Mark plan complete**

The data pipeline is shippable when:
- All pytest tests pass
- The local dry-run produces a JSON with > 25 tickers
- The GitHub Actions workflow has run successfully at least once on a manual trigger
- The R2 bucket contains the JSON and it's publicly fetchable via `curl`

---

## Coverage check

| Spec requirement | Task |
|---|---|
| Daily scrape Yahoo / SGinvestors / SGX | 4, 5, 6, 11 |
| Risk score 0–100 with 5 components | 7 |
| JSON schema in spec | 2, 8 |
| Cloudflare R2 upload | 10 |
| GitHub Actions cron | 12 |
| Failure alerts via Telegram | 9, 11 |
| Hermetic tests with fixtures | 4, 5, 6 |
| Score audit / spot check | 13 |
