# Privacy Policy for APY

**Last updated:** 2026-05-28

APY ("the app") is an educational tool for simulating dividend portfolios using publicly available data on Singapore Exchange (SGX) listed securities. This privacy policy explains what data APY collects, stores, and transmits.

## Short version

**APY does not collect, store, transmit, or share any personal data.** No accounts, no analytics, no advertising, no third-party trackers. Your inputs (capital, risk level, horizon) stay on your device.

## Long version

### Data we DO NOT collect

- Personal identification (name, email, phone, address)
- Apple ID, device identifiers, or any account credentials
- Location data
- Contacts, photos, microphone, camera, or any sensor data
- Behavioral analytics (taps, screen views, time-in-app)
- Crash reports (we do not use Sentry, Firebase Crashlytics, or any third-party crash reporter)
- Advertising identifiers (IDFA)

### Data we DO transmit

APY fetches one publicly accessible JSON file from a Cloudflare R2 bucket on app open:
- File name: `sg_dividend_universe.json`
- Contents: Singapore Exchange ticker symbols, current prices, dividend yields, dividend history, and computed risk scores
- This is the same data anyone can scrape from Yahoo Finance, SGX, and SGinvestors.io
- Your IP address is briefly visible to Cloudflare during this fetch (standard for any web request) but no other identifier is sent

The fetched JSON is cached on your device for offline use. We do not transmit anything back.

### Data stored on your device

- The fetched universe JSON (text, < 50 KB)
- Your last-used input preferences (capital, risk level, horizon) via Apple's standard `UserDefaults` (called `SharedPreferences` in our Flutter app)

This data never leaves your device. Uninstalling the app removes it.

### Third-party services

- **Cloudflare R2** — content delivery for the universe JSON. Cloudflare may log your IP and the request URL per their own privacy policy: https://www.cloudflare.com/privacypolicy/
- **Apple App Store and TestFlight** — distribution of the app itself, subject to Apple's privacy policy: https://www.apple.com/legal/privacy/
- **No other third-party services are used by the app.**

### Children's privacy

APY is rated 4+ and contains no content directed at children. We do not knowingly collect data from anyone, including children under 13.

### Changes to this policy

If we ever change what APY collects or transmits, we will update this policy and bump the "Last updated" date. There is no version of APY that has ever transmitted personal data, and we have no plans to add such functionality.

### Not financial advice

This section is not strictly about privacy, but it bears repeating: APY is an educational simulator. The allocations it suggests are illustrative outputs of a transparent rule-based optimizer that you parameterise. APY is not regulated by the Monetary Authority of Singapore (MAS) as a Financial Adviser. Always consult a licensed adviser for personal financial decisions.

### Contact

Built by Daniel Choong. Issues, questions, or data corrections: open an issue at https://github.com/UncleChoong/sg-dividend-app or email danielchoong5@gmail.com.
