# APY Launch Checklist

A single sheet to walk you from "TestFlight build with friends" → "Live on App Store." Tick as you go.

## Phase 1 — Friends testing (you're here)

- [x] App in TestFlight
- [x] APY rebrand + multi-tab restructure
- [x] Pendle-style dark theme
- [ ] Real app icon ← (subagent working on this overnight)
- [ ] Real SGX data via yfinance ← (subagent working on this overnight)
- [ ] **Add 3-5 friends as Internal Testers** in App Store Connect → TestFlight → Internal Testing → Internal testers group. Each tester needs their Apple ID email.
- [ ] Collect feedback: what's broken, what's confusing, what's missing? Note 3-5 must-fix issues before next phase.

## Phase 2 — Real data flowing (when you're ready)

- [ ] **Cloudflare R2 bucket** created. 5 min: cloudflare.com → R2 → Create bucket `sg-dividend` → API tokens → create token with Object R/W → note Account ID + Access Key ID + Secret.
- [ ] **GitHub Actions secrets** added to `sg-dividend-data` repo. Settings → Secrets → Actions. Add: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, optionally `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID`.
- [ ] **Manually trigger** the `refresh-universe` workflow: GitHub → sg-dividend-data → Actions tab → "refresh-universe" → Run workflow → main.
- [ ] **Verify R2** has the file at `https://<bucket>.<account>.r2.cloudflarestorage.com/sg_dividend_universe.json` (or your public-access URL).
- [ ] **Update `UNIVERSE_URL`** in Codemagic env var (`app_secrets` group) to the real R2 URL.
- [ ] **Trigger a new Codemagic build** → next TestFlight build uses real data.

## Phase 3 — Public TestFlight (broader testing, ~3-7 days)

- [ ] **External Testing group**: App Store Connect → TestFlight → External Testing → "+". Apple does a light "Beta App Review" (24-48h).
- [ ] After approval, you get a **public TestFlight link** (looks like `https://testflight.apple.com/join/XXXXXXXX`). Share on Twitter, r/singaporefi, finance Telegram groups, etc.
- [ ] Up to 10,000 external testers. Collect a wider feedback batch.

## Phase 4 — App Store submission (production launch)

Required materials (drafts in `APP_STORE_METADATA.md`):

- [ ] **App name, subtitle, description, keywords** — paste from APP_STORE_METADATA.md
- [ ] **Support URL** — use GitHub repo or set up a Google Form for feedback
- [ ] **Privacy Policy URL** — `https://unclechoong.github.io/sg-dividend-app/privacy.html` (GitHub Pages already enabled by overnight work)
- [ ] **Screenshots** — 6.7" iPhone (1290×2796). Take from iOS Simulator on a Mac, or from your iPhone via Apple's "Screenshot" feature when running the app. 6 screenshots needed:
   1. Landing screen
   2. Home dashboard
   3. Stocks list
   4. Stock detail with dividend history chart
   5. Optimize tab with industry filter
   6. Result with allocation pie + simulator
- [ ] **App preview video** (optional) — 15-30 sec, captured on iPhone or in QuickTime
- [ ] **Age rating** — walk Apple's questionnaire, all answers "None" → 4+ rating
- [ ] **App Information**: primary category Finance, secondary Productivity
- [ ] **Pricing** — Free, all countries
- [ ] **App Review Information** — your contact details, no demo account needed
- [ ] **Pick the latest TestFlight build** as the binary for submission
- [ ] **Submit for Review** → choose "Manually release this version" for first launch
- [ ] **Apple reviews** in 1-3 days (sometimes same day)
- [ ] **On approval** → tap "Release This Version" → live on App Store in ~1 hour

## Phase 5 — Post-launch (next 30 days)

- [ ] **Monitor crashes** — App Store Connect → Analytics → Crashes (no Sentry yet, but Apple's own crash reports show up here)
- [ ] **Read every App Store review** — respond to negatives within 24h
- [ ] **Iterate** — push fixes via Codemagic → new TestFlight → submit update to App Store
- [ ] **Marketing** — Twitter post, r/singaporefi post, message in SeedlyTG / Singapore investing Discords
- [ ] **Hand-curate the SGX_DIVIDEND_TICKERS** list to add tickers users ask for — likely Frasers, Mapletree subsets, Sasseur REIT, etc.

## Open issues from code review (deferred until users complain)

Documented in `docs/superpowers/reviews/2026-05-27-final-review.md`. Most are minor. The two worth proactive fixing:

- [ ] Tighten Yahoo parser to handle sidebar-data risk (yfinance switch should make this moot)
- [ ] Add property tests for optimizer (regression coverage for diversification caps)

## Money budget (running total)

| Item | Cost |
|------|------|
| Apple Developer Program | US$99/yr |
| Cloudflare R2 (free tier covers MVP) | $0 |
| GitHub (public repos) | $0 |
| Codemagic (free tier 500 min/mo) | $0 |
| Domain (optional, for marketing site) | ~S$15/yr |
| **Total before revenue** | **~US$100/yr** |

That's the whole cost of being "first in Singapore with a dividend optimizer iOS app."
