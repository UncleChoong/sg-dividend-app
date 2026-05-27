"""Take the data pipeline's universe.json and enrich with descriptions / market caps.

Run from repo root: python scripts/enrich_bundled_json.py
"""
from __future__ import annotations
import json
import os
from pathlib import Path

SRC = Path("C:/Users/USER/sg-dividend-data/universe.json")
DEST = Path("C:/Users/USER/sg-dividend-app/assets/bundled_universe.json")

ENRICHMENT = {
    "D05":  {"name": "DBS Group", "description": "Singapore's largest bank by assets, with operations across Asia. A consistent dividend payer with strong CET-1 capital ratios.", "market_cap_sgd": 175_000_000_000, "industry": "Banks"},
    "O39":  {"name": "OCBC", "description": "Second-largest Singapore bank, with strong presence in Greater China and Southeast Asia. Steady semi-annual dividend record.", "market_cap_sgd": 105_000_000_000, "industry": "Banks"},
    "U11":  {"name": "United Overseas Bank", "description": "Third local bank, with major Southeast Asia regional franchise. Reliable dividend, conservative balance sheet.", "market_cap_sgd": 63_000_000_000, "industry": "Banks"},
    "Z74":  {"name": "Singtel", "description": "Largest Singapore telco, with regional stakes in Optus (Australia), Bharti Airtel (India), and others. Yield-focused after asset rationalisation.", "market_cap_sgd": 74_000_000_000, "industry": "Telco"},
    "CC3":  {"name": "StarHub", "description": "Singapore's second-largest telecom. Smaller scale than Singtel; dividend cut in recent years as fixed-line revenue declined.", "market_cap_sgd": 1_800_000_000, "industry": "Telco"},
    "AJBU": {"name": "Keppel DC REIT", "description": "Singapore's pure-play data centre REIT, with assets across Asia-Pacific and Europe. Beneficiary of AI/cloud capex.", "market_cap_sgd": 4_500_000_000, "industry": "Utilities"},
    "CJLU": {"name": "NetLink NBN Trust", "description": "Owner of Singapore's nationwide fibre broadband network. Regulated returns, defensive yield play.", "market_cap_sgd": 3_800_000_000, "industry": "Utilities"},
    "A17U": {"name": "Ascendas REIT", "description": "Singapore's largest industrial REIT, with logistics, business space, and data centre assets across SG, Australia, US, Europe.", "market_cap_sgd": 11_500_000_000, "industry": "REITs"},
    "C38U": {"name": "CapitaLand Integrated Commercial Trust", "description": "Largest Singapore retail+office REIT. Anchor assets include Plaza Singapura, Funan, Asia Square. Defensive blue-chip REIT.", "market_cap_sgd": 15_000_000_000, "industry": "REITs"},
    "M44U": {"name": "Mapletree Logistics Trust", "description": "Asia-Pacific logistics REIT with 180+ properties across 9 countries. Dividend pressure from rising rates.", "market_cap_sgd": 6_800_000_000, "industry": "REITs"},
    "N2IU": {"name": "Mapletree Pan Asia Commercial Trust", "description": "Office-retail REIT covering SG, HK, China, Japan, Korea. Higher leverage and FX exposure than peers.", "market_cap_sgd": 6_700_000_000, "industry": "REITs"},
    "ME8U": {"name": "Mapletree Industrial Trust", "description": "Industrial + data centre REIT. ~55% US data centres, ~40% Singapore industrial. Active capital recycling.", "market_cap_sgd": 6_400_000_000, "industry": "REITs"},
    "T82U": {"name": "Suntec REIT", "description": "Office + retail REIT centred on Suntec City Mall and One Raffles Quay. Higher debt cost sensitivity.", "market_cap_sgd": 4_200_000_000, "industry": "REITs"},
    "J69U": {"name": "Frasers Centrepoint Trust", "description": "Suburban Singapore retail REIT - Causeway Point, Northpoint City, Tampines 1. Defensive consumer staples mix.", "market_cap_sgd": 4_100_000_000, "industry": "REITs"},
    "BUOU": {"name": "Frasers Logistics & Commercial Trust", "description": "Australia/Europe-focused logistics + commercial REIT. Higher growth profile but FX-exposed.", "market_cap_sgd": 3_600_000_000, "industry": "REITs"},
    "C2PU": {"name": "Parkway Life REIT", "description": "Asia's largest listed healthcare REIT - Singapore + Japan hospitals/nursing homes. CPI-linked rentals.", "market_cap_sgd": 2_700_000_000, "industry": "REITs"},
    "AU8U": {"name": "CapitaLand China Trust", "description": "China retail + business park REIT. Subject to China property/consumer sentiment headwinds.", "market_cap_sgd": 1_300_000_000, "industry": "REITs"},
    "M1GU": {"name": "Mapletree Industrial Trust (units)", "description": "Alternative Mapletree industrial-focused REIT vehicle. Smaller scale than M44U.", "market_cap_sgd": 1_500_000_000, "industry": "REITs"},
    "U96":  {"name": "Sembcorp Industries", "description": "Energy + urban infrastructure conglomerate, transitioning to renewables. Improving dividend trajectory.", "market_cap_sgd": 11_000_000_000, "industry": "Industrials"},
    "S58":  {"name": "SATS", "description": "Airline ground handling + in-flight catering. Recovering post-COVID with WFS acquisition.", "market_cap_sgd": 3_900_000_000, "industry": "Industrials"},
    "S63":  {"name": "ST Engineering", "description": "Defence, aerospace, smart-cities conglomerate. Stable order book, reliable dividend grower.", "market_cap_sgd": 13_400_000_000, "industry": "Industrials"},
    "Y92":  {"name": "Thai Beverage", "description": "Thailand's largest beverage producer (Chang Beer). Stable cash flows, listed on SGX.", "market_cap_sgd": 11_500_000_000, "industry": "Consumer"},
    "C07":  {"name": "Jardine Cycle & Carriage", "description": "Astra International (Indonesia) majority owner. Auto, financial services, agribusiness exposure.", "market_cap_sgd": 7_000_000_000, "industry": "Consumer"},
    "BN4":  {"name": "Keppel Corp", "description": "Asset-light infrastructure, real estate, asset management. Spun off offshore marine in 2024.", "market_cap_sgd": 12_500_000_000, "industry": "Industrials"},
    "F34":  {"name": "Wilmar International", "description": "Asia's leading agribusiness - edible oils, sugar, grains. Commodity-cycle exposed.", "market_cap_sgd": 18_000_000_000, "industry": "Consumer"},
    "S68":  {"name": "Singapore Exchange", "description": "Operator of SGX itself. Diversified across cash equities, derivatives, FX. Monopoly profile.", "market_cap_sgd": 13_500_000_000, "industry": "Industrials"},
    "ES3":  {"name": "SPDR Straits Times Index ETF", "description": "Tracks the FTSE Straits Times Index - the 30 largest SGX stocks. Most widely held SG ETF.", "market_cap_sgd": 1_700_000_000, "industry": "Other"},
    "QL3":  {"name": "iShares USD Asia HY Bond ETF", "description": "Asian high-yield USD bond exposure. Higher yield, higher credit risk than government bonds.", "market_cap_sgd": 300_000_000, "industry": "Other"},
    "G3B":  {"name": "Nikko AM STI ETF", "description": "Alternative STI tracker - same underlying as ES3 but different fee/structure. Used for SRS investing.", "market_cap_sgd": 800_000_000, "industry": "Other"},
}


def main() -> int:
    if not SRC.exists():
        print(f"ERROR: source not found at {SRC}. Run the data pipeline first.")
        return 1
    data = json.loads(SRC.read_text())
    enriched = 0
    for entry in data["universe"]:
        t = entry["ticker"]
        if t in ENRICHMENT:
            e = ENRICHMENT[t]
            entry["name"] = e["name"]
            entry["description"] = e["description"]
            entry["market_cap_sgd"] = e["market_cap_sgd"]
            entry["industry"] = e["industry"]
            enriched += 1
        else:
            entry["description"] = ""
            entry["market_cap_sgd"] = None
            entry["industry"] = entry["sector"]
    DEST.parent.mkdir(parents=True, exist_ok=True)
    DEST.write_text(json.dumps(data, indent=2))
    print(f"Enriched {enriched} of {len(data['universe'])} tickers")
    print(f"Wrote {DEST} ({os.path.getsize(DEST)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
