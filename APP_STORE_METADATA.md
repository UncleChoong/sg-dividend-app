# App Store Connect Submission Metadata

Copy-paste these into App Store Connect → My Apps → SG Dividend Optimizer (or rename to APY) when ready for public submission. None of this is needed for internal TestFlight.

## App Information

**Name** (max 30 chars):
```
APY - SG Dividend Yields
```

**Subtitle** (max 30 chars):
```
Singapore dividend optimizer
```

**Bundle ID:** `sg.dividend.sgDividend` (already set)

**Primary Category:** Finance
**Secondary Category:** Productivity

## Description (max 4000 chars)

```
APY is an educational simulator for Singapore retail investors who want to maximise dividend income from SGX-listed stocks.

Given a capital amount (e.g. S$10,000), a risk preference (Conservative, Neutral, or Aggressive), and a time horizon, APY computes an illustrative allocation across SGX dividend stocks — banks, REITs, business trusts, telcos, and ETFs — and projects your annual dividend income forward over 1, 5, 10, or 20 years with optional dividend reinvestment (DRIP) and monthly contributions.

WHAT'S DIFFERENT

Most dividend trackers show you what you already own. APY shows you what to consider buying for your situation: the right basket of SGX stocks, balanced by sector, that maximises yield within your chosen risk band.

HOW IT WORKS

• Pick your capital, risk level, and horizon
• APY filters its curated SGX dividend universe by a transparent rule-based risk score (sector, market cap, payout ratio, dividend volatility, price volatility)
• It greedily fills your basket with the highest-yielding eligible tickers, subject to: max 25% per ticker, max 40% per sector, minimum 5 holdings
• A forward simulator shows your projected portfolio value with and without DRIP

EVERY CHOICE IS EXPLAINED

Tap "Why these stocks?" on any result to see the score breakdown for each ticker. No black-box magic — the optimizer's logic is fully transparent.

ALSO IN APY

• Browse all tracked SGX dividend stocks with 3-year cumulative yield
• Drill into any stock for company info, 5-year dividend history, and full score breakdown
• Filter the optimizer by industry (include/exclude Banks, REITs, Telco, Utilities, etc.)

NOT FINANCIAL ADVICE

APY is an educational tool. It is not regulated by the Monetary Authority of Singapore (MAS) as a Financial Adviser. The allocations shown are illustrative outputs of a rule-based optimizer you parameterise yourself — not personal recommendations. Past dividends do not guarantee future payments. Always verify against your broker before transacting. If you need advice, speak to a MAS-licensed financial adviser.

Data updates daily from public sources. Built independently by a retail investor in Singapore.
```

## Keywords (max 100 chars, comma-separated, no spaces after commas)

```
dividend,sgx,reit,singapore,yield,portfolio,investing,stocks,passive income,drip,asset allocation
```

## What's New (per release, max 4000 chars)

For v0.1.0 (first release):
```
First public release of APY.

• Optimize an SGX dividend portfolio from S$1,000 upwards
• Three risk levels: Conservative, Neutral, Aggressive
• Forward simulator with DRIP and monthly contributions
• Browse 30+ tracked SGX dividend stocks
• 5-year dividend history per stock
• Industry filter for targeted optimization

Built by a retail investor for retail investors. Feedback welcome.
```

## URLs

**Support URL** (required): `https://github.com/UncleChoong/sg-dividend-app`
or set up a simple Google Form for feedback and use its URL.

**Marketing URL** (optional): leave blank for first release.

**Privacy Policy URL** (REQUIRED — `docs/privacy.html` is already in the repo; enable GitHub Pages once):
- URL after enabling: `https://unclechoong.github.io/sg-dividend-app/privacy.html`
- One-time setup: GitHub repo → Settings → Pages → Source: "Deploy from a branch" → Branch: `main`, Folder: `/docs` → Save. URL goes live in ~30 seconds.
- Verify by visiting the URL in a browser before submitting to App Store.

## Age Rating

Walk through Apple's questionnaire. For APY, ALL answers are "None" — no gambling, no violence, no profanity, no mature themes. Result will be 4+.

## Pricing

**Price tier:** Free
**Availability:** All countries (or restrict to Singapore if you prefer)

## App Review Information

**Contact:**
- First Name: Daniel
- Last Name: Choong
- Phone: your number
- Email: danielchoong5@gmail.com

**Demo account:** Not needed (no login).

**Notes for the reviewer:**
```
This app is an educational simulator for Singapore-listed dividend stocks. It does not provide financial advice and is not regulated by MAS. All allocations shown are illustrative outputs of a transparent rule-based optimizer the user parameterises themselves.

The app fetches public market data (prices, dividend yields) from a JSON file hosted on Cloudflare R2, updated daily by a separate scraper. No user data is collected. No accounts or login required.

To test:
1. Tap "Enter" on the landing screen
2. Tap "Optimize" tab in the bottom navigation
3. Default capital S$10,000, risk Neutral, horizon 5 years already set — tap "Optimize Portfolio"
4. Review the suggested allocation, then tap the chart icon for forward simulation, or the help icon for the rationale per ticker
```

## Screenshots required

iOS 6.7" (iPhone 15 Pro Max, 1290 × 2796):
1. Landing screen with "APY" wordmark and Enter CTA
2. Home tab showing dashboard cards
3. Stocks tab list with yields
4. Stock Detail with 5y dividend history bar chart
5. Optimize tab with industry filter chips
6. Result screen with allocation pie + projected income

iOS 6.5" (iPhone XS Max, 1242 × 2688) and 5.5" (iPhone 8 Plus, 1242 × 2208) — Apple lets you re-use the 6.7" set since iOS 17.

Take these from a connected iPhone or the iOS Simulator (Mac required).

## Export Compliance

Already answered "No encryption" — App Store Connect remembers per app. New uploads still need the per-build confirmation in TestFlight, but the App Store submission only asks once.

## Submission flow

1. Fill all metadata above in App Store Connect
2. Upload screenshots
3. Pick build (use the latest TestFlight build)
4. Submit for Review → "Manually release this version" for first launch (gives you time to coordinate)
5. Apple reviews in 1-3 days typically
6. On approval, tap "Release This Version" → live on App Store within ~1 hour
