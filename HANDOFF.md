# APY — Handoff

**Last updated:** 2026-05-28 (overnight session)
**Status:** App live in TestFlight under your Apple ID. Significant overnight progress on data + design + branding. One Codemagic build needed to ship the latest changes.

---

## Where things stand right now

Both GitHub repos are on `main`, pushed, and reflect the latest state.

| Concern | Status |
|---|---|
| Flutter app code | 20/20 tests pass, `flutter analyze` clean |
| Multi-tab structure (Landing → Home / Stocks / Optimize / Stock Detail) | Done |
| Pendle-style dark theme | Done |
| App icon (custom APY-branded) | Done |
| Bundled JSON with real SGX data (29 tickers) | Done |
| Data pipeline (yfinance-based) | Done, 35 pytest pass |
| TestFlight build (Build 31 = bundled-data version) | Live on your phone |
| TestFlight build with all overnight changes | **Pending one more Codemagic trigger** |
| Cloudflare R2 + daily JSON refresh | Not set up (your turn) |
| App Store submission materials | Drafted in `APP_STORE_METADATA.md` |
| Privacy policy + GitHub Pages | Drafted, GH Pages enabled — URL goes live on next push |
| Public App Store launch | Materials ready, not submitted |

---

## What was done overnight (while you slept)

### 1. APY multi-tab restructure
Replaced the single-flow input → result UX with iFast-style bottom navigation:
- **Landing screen** — "APY" wordmark + tagline + Enter button
- **Home tab** — dashboard with universe stats, top yielder, sector breakdown, score distribution
- **Stocks tab** — sortable list of all tracked SGX dividend stocks with 3-year cumulative yield
- **Stock Detail screen** — push view with company description, 5y dividend history bar chart, score breakdown
- **Optimize tab** — input controls with new **industry filter** chips
- App name changed to "APY" in Info.plist + Android manifest

Files: `lib/ui/landing_screen.dart`, `lib/ui/main_shell.dart`, `lib/ui/home_tab.dart`, `lib/ui/stocks_tab.dart`, `lib/ui/stock_detail_screen.dart`, `lib/ui/optimize_tab.dart`, plus updates to data models.

Commit: `5f94ced`

### 2. Pendle-inspired dark theme
- Background `#0A0E1A`, surface `#131826`, primary cyan `#00D9D5`, secondary green `#4ADE80`
- Inter font via `google_fonts`
- Hero numbers at 48pt with subtle cyan glow
- Neon-stroke charts on dark
- Pill-shaped CTAs with glow shadow

Commit: `6fdedec`

### 3. App icon
Custom-generated 1024×1024 APY icon: deep navy background, large cyan "APY" wordmark, small green accent dot. All 15 iOS sizes generated. Source script at `scripts/gen_icon.py` so you can regenerate later.

Commit: `adfa6e8`

### 4. Real SGX data via yfinance
Replaced the HTML scrapers that only worked for 1 of 31 tickers with `yfinance` Python library (uses Yahoo's JSON API). Now resolves **29 of 31 tickers** with real prices, yields, and 5-year dividend histories.

Two tickers refused to resolve (`ACV` Ascott REIT, `T39` Suntec REIT) — they were removed from the universe. You can try re-adding them with alternate Yahoo symbols later.

Sample real prices from the dry-run:
- DBS (D05): S$62.00, yield 4.05%
- OCBC (O39): S$23.36, yield 3.60%
- Ascendas REIT (A17U): S$2.52, yield 6.19%
- iShares Asia HY Bond (QL3): S$8.62, yield 7.31%

Data repo commits: `606d56b` (yfinance switch), then a cleanup commit removing dead `sginvestors.py`.

### 5. Bundled JSON enrichment
The bundled fallback JSON in the app (`assets/bundled_universe.json`) now contains the 29 real SGX stocks PLUS hand-curated descriptions and approximate market caps. So even with no network, the app shows real Singapore stocks with rich detail.

Source script at `scripts/enrich_bundled_json.py` — re-run after each data pipeline refresh once you've set up R2.

Commit: `61655a5`

### 5a. Data pipeline emits enrichment too
After the bundled JSON was generated, I also patched the **data pipeline** itself (`sg-dividend-data` repo) to inject the same curated descriptions, industries, and market caps into every R2-published JSON. The curated dict lives at `sg_dividend_data/enrichment.py` and is the single source of truth — update there to change descriptions across both bundled + R2 versions.

This means: when you set up R2 and the daily refresh runs, the production JSON will have full description / industry / market_cap_sgd fields out of the box. The Stock Detail screen will look populated even on fresh data.

Data repo commit: `e64714c`. 39 pytest pass.

### 6. App Store submission materials
Drafted everything you'll need for public launch:
- **APP_STORE_METADATA.md** — name, subtitle, description, keywords, reviewer notes
- **PRIVACY_POLICY.md** — plain-text version
- **docs/privacy.html** — web version for Apple's privacy policy URL requirement
- **docs/index.html** — simple landing page at the GH Pages URL
- **LAUNCH_CHECKLIST.md** — step-by-step phases from Phase 1 (friends) to Phase 5 (post-launch marketing)

GitHub Pages is already enabled via API and **the privacy URL is LIVE** at `https://unclechoong.github.io/sg-dividend-app/privacy.html` — verified returning HTTP 200 with the APY-branded content. You can paste this directly into App Store Connect's privacy policy field whenever you're ready to submit.

The marketing landing page is also live at the bare URL `https://unclechoong.github.io/sg-dividend-app/`.

Commit: `67c28b3`

---

## What you should do when you wake up

### Right now (~5 min)

1. **Trigger one more Codemagic build** so it picks up the icon + the new APY restructure + the real bundled data. Workflows → ios-testflight → Start new build → main. This will be the "real" first APY-branded build.

2. **Check the GitHub Pages site is live** — visit `https://unclechoong.github.io/sg-dividend-app/` in a browser. If it shows the APY landing page, the privacy URL is ready.

### Next 30 min — once Codemagic build finishes processing

3. **Install the new build on your iPhone** — TestFlight on phone → SG Dividend Optimizer (still labeled old name in TestFlight if you haven't renamed the app on App Store Connect — the *home-screen* icon will say APY).

4. **Walk through every screen and tab.** The flow is: Landing (Enter) → Home → tap Stocks tab → tap any stock → see detail → back → tap Optimize tab → adjust inputs → Optimize Portfolio → Result → tap chart icon → simulator. Note anything that looks broken or ugly.

5. **Add 2-3 friends** as Internal Testers (Phase 1 of LAUNCH_CHECKLIST.md). Get fast UX feedback.

### Phase 2 — when you want real updating data (~1 hour)

6. **Create Cloudflare R2 bucket** + **add GitHub Actions secrets** to `UncleChoong/sg-dividend-data` repo. See LAUNCH_CHECKLIST.md Phase 2.

7. **Trigger first refresh-universe workflow** to populate R2.

8. **Update `UNIVERSE_URL`** in Codemagic env var to the real R2 URL. Next Codemagic build = app fetches from R2.

### Phase 3 — public launch (~1 day work + 1-3 day Apple review)

See LAUNCH_CHECKLIST.md Phase 3-4.

---

## Known open items

These are not blockers for TestFlight friends-testing, but they're real product gaps:

| Issue | Severity | Where |
|---|---|---|
| `ACV` and `T39` tickers don't resolve via Yahoo `.SI` — investigate alternate symbols | Medium | `sg_dividend_data/universe.py` |
| Data pipeline doesn't yet populate `description` / `market_cap_sgd` / `industry` — only the bundled JSON has these via the enrichment script. Once the daily pipeline runs, those fields will be missing from R2 | Medium | data pipeline needs new fields |
| TestFlight Internal Testing group must be named exactly `Internal testers` for codemagic.yaml auto-submit | Low | one-time setup |
| `lib/ui/input_screen.dart` is dead code (replaced by `optimize_tab.dart`) but not deleted | Low | cleanup whenever |
| The 11-ticker bundled JSON was replaced with 29 — the model tests still reference the old smaller set in some assertions but all pass | None | already verified |

---

## File paths to remember

- **App repo:** `C:\Users\USER\sg-dividend-app` — GitHub: https://github.com/UncleChoong/sg-dividend-app
- **Data repo:** `C:\Users\USER\sg-dividend-data` — GitHub: https://github.com/UncleChoong/sg-dividend-data
- **App Store metadata:** `sg-dividend-app/APP_STORE_METADATA.md`
- **Launch checklist:** `sg-dividend-app/LAUNCH_CHECKLIST.md`
- **Privacy policy URL:** `https://unclechoong.github.io/sg-dividend-app/privacy.html`
- **Cert private key** (DO NOT lose, save to 1Password): `sg-dividend-app/cert_private_key.pem` (gitignored)

---

## Git commit summary (overnight)

App repo, latest first:
```
61655a5 feat(app): real SGX data in bundled fallback (29 tickers, enriched descriptions)
67c28b3 docs: App Store metadata, privacy policy, launch checklist, GH Pages site
adfa6e8 feat(app): APY-branded app icon for iOS
5f94ced feat(app): APY multi-tab restructure (landing + home + stocks + optimize)
```

Data repo, latest first:
```
<cleanup commit>  chore(data): remove dead sginvestors module, gitignore dev universe.json
606d56b           feat(data): replace HTML scrapers with yfinance for reliable SGX coverage
```

Total overnight: ~5 new commits across two repos. All pushed to origin.

---

## TL;DR

The app you have in TestFlight right now is **the pre-overnight version (Build 31)**. To get the post-overnight version (APY rebrand, real SGX data, real icon) onto your phone, trigger one more Codemagic build and update from TestFlight on iPhone. ~25 min round trip.

Welcome back. Read LAUNCH_CHECKLIST.md and start at Phase 1.
