# APY Multi-Tab Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the SG Dividend app into a multi-tab "APY" app with Landing → Home/Stocks/Optimize bottom nav, adding Stocks list, Stock Detail, and industry filter to optimizer.

**Architecture:** Keep all domain logic unchanged; add new fields to models with backward-compat defaults; add new screens as separate files; wire navigation through a new MainShell; keep SplashScreen but redirect to LandingScreen after load.

**Tech Stack:** Flutter, Riverpod, fl_chart, google_fonts, intl — no new dependencies.

---

## File Map

### Files to MODIFY
- `assets/bundled_universe.json` — add `description`, `industry`, `market_cap_sgd` per ticker
- `lib/data/models.dart` — add `description`, `industry`, `marketCapSgd`, `threeYearCumulativeYieldPct` to Ticker
- `lib/domain/optimizer.dart` — add `includedIndustries` optional param
- `lib/app.dart` — change title to APY
- `lib/ui/splash_screen.dart` — redirect to LandingScreen instead of InputScreen
- `lib/ui/result_screen.dart` — accept optional `includedIndustries` param
- `pubspec.yaml` — update description
- `ios/Runner/Info.plist` — CFBundleDisplayName/CFBundleName → APY
- `android/app/src/main/AndroidManifest.xml` — android:label → APY
- `test/domain/optimizer_test.dart` — add industry filter test + update mk() helper
- `test/data/models_test.dart` — add new-fields tests

### Files to CREATE
- `lib/ui/landing_screen.dart` — APY wordmark + Enter button → MainShell
- `lib/ui/main_shell.dart` — bottom NavigationBar with 3 tabs
- `lib/ui/home_tab.dart` — dashboard with hero cards
- `lib/ui/stocks_tab.dart` — scrollable ticker list with sort dropdown
- `lib/ui/stock_detail_screen.dart` — company info + div history bar chart + score breakdown
- `lib/ui/optimize_tab.dart` — InputScreen content + industry FilterChips

### Files to DELETE (conceptually — kept as dead code is fine)
- `lib/ui/input_screen.dart` — replaced by optimize_tab.dart (keep file, just stop routing to it)

---

## Task 1: Enrich bundled_universe.json

**Files:**
- Modify: `assets/bundled_universe.json`

- [ ] **Step 1: Write the enriched JSON**

Replace the file with enriched entries (all 11 tickers get `description`, `industry`, `market_cap_sgd`):

```json
{
  "generated_at": "2026-05-27T00:00:00+08:00",
  "schema_version": 1,
  "universe": [
    {"ticker":"D05","name":"DBS Group","sector":"Banks","industry":"Banks","description":"Singapore's largest bank by assets, with pan-Asian operations across 18 markets. A consistent dividend payer with strong CET-1 capital ratios.","market_cap_sgd":150000000000,"price":42.10,"yield_pct":5.1,"score":18,"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":5,"price_vol":11},"lot_size":100,"div_history_5y":[1.92,1.62,1.44,1.20,1.20]},
    {"ticker":"O39","name":"OCBC","sector":"Banks","industry":"Banks","description":"Oversea-Chinese Banking Corporation, the second-largest bank in Singapore by assets, with a strong insurance arm via Great Eastern.","market_cap_sgd":85000000000,"price":15.20,"yield_pct":5.6,"score":15,"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":3,"price_vol":10},"lot_size":100,"div_history_5y":[0.85,0.84,0.68,0.53,0.53]},
    {"ticker":"U11","name":"UOB","sector":"Banks","industry":"Banks","description":"United Overseas Bank, one of Singapore's three major local banks, with a growing ASEAN retail franchise following its Citigroup consumer acquisition.","market_cap_sgd":50000000000,"price":29.80,"yield_pct":5.4,"score":17,"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":4,"price_vol":11},"lot_size":100,"div_history_5y":[1.70,1.50,1.35,0.78,1.30]},
    {"ticker":"Z74","name":"Singtel","sector":"Telco","industry":"Telco","description":"Singapore's largest telecommunications group by revenue, with regional associates spanning Australia (Optus), India (Airtel), and Southeast Asia.","market_cap_sgd":28000000000,"price":3.50,"yield_pct":5.2,"score":25,"score_breakdown":{"sector":15,"mcap":0,"div_vol":5,"payout":0,"price_vol":5},"lot_size":100,"div_history_5y":[0.15,0.149,0.09,0.075,0.175]},
    {"ticker":"A17U","name":"Ascendas REIT","sector":"REITs","industry":"REITs","description":"Singapore's largest industrial REIT by market cap, owning business parks, logistics, and data centre assets across Singapore, Australia, and the US.","market_cap_sgd":12000000000,"price":2.60,"yield_pct":5.9,"score":42,"score_breakdown":{"sector":27,"mcap":0,"div_vol":0,"payout":10,"price_vol":5},"lot_size":100,"div_history_5y":[0.155,0.152,0.150,0.149,0.146]},
    {"ticker":"C38U","name":"CapitaLand Integrated Commercial Trust","sector":"REITs","industry":"REITs","description":"Singapore's largest retail-and-office REIT, owning flagship malls such as Plaza Singapura and CapitaSpring office tower.","market_cap_sgd":14000000000,"price":2.05,"yield_pct":5.5,"score":40,"score_breakdown":{"sector":27,"mcap":0,"div_vol":0,"payout":8,"price_vol":5},"lot_size":100,"div_history_5y":[0.106,0.104,0.098,0.087,0.108]},
    {"ticker":"M44U","name":"Mapletree Logistics Trust","sector":"REITs","industry":"REITs","description":"Pan-Asian logistics REIT managing warehouses and distribution centres across nine countries including Singapore, China, Japan, and Australia.","market_cap_sgd":7000000000,"price":1.40,"yield_pct":6.1,"score":45,"score_breakdown":{"sector":27,"mcap":3,"div_vol":0,"payout":10,"price_vol":5},"lot_size":100,"div_history_5y":[0.086,0.090,0.085,0.082,0.081]},
    {"ticker":"S63","name":"ST Engineering","sector":"Industrials","industry":"Industrials","description":"Singapore-listed global technology, defence, and engineering group with operations in aerospace MRO, smart city, and defence electronics.","market_cap_sgd":12000000000,"price":4.30,"yield_pct":3.7,"score":22,"score_breakdown":{"sector":17,"mcap":0,"div_vol":0,"payout":0,"price_vol":5},"lot_size":100,"div_history_5y":[0.16,0.16,0.16,0.15,0.15]},
    {"ticker":"S68","name":"Singapore Exchange","sector":"Industrials","industry":"Industrials","description":"SGX operates Singapore's securities and derivatives exchanges, providing multi-asset clearing and index services across Asian markets.","market_cap_sgd":11000000000,"price":11.20,"yield_pct":3.0,"score":20,"score_breakdown":{"sector":17,"mcap":0,"div_vol":0,"payout":0,"price_vol":3},"lot_size":100,"div_history_5y":[0.34,0.32,0.32,0.30,0.30]},
    {"ticker":"ES3","name":"SPDR STI ETF","sector":"Other","industry":"Other","description":"Exchange-traded fund tracking the Straits Times Index, offering diversified exposure to Singapore's 30 largest listed companies in a single instrument.","market_cap_sgd":1500000000,"price":3.50,"yield_pct":3.8,"score":23,"score_breakdown":{"sector":22,"mcap":0,"div_vol":0,"payout":0,"price_vol":1},"lot_size":100,"div_history_5y":[0.12,0.12,0.11,0.10,0.13]},
    {"ticker":"QL3","name":"iShares USD Asia High Yield Bond ETF","sector":"Other","industry":"Other","description":"Bond ETF providing exposure to USD-denominated high-yield debt issued by Asia-Pacific companies, offering monthly income distributions.","market_cap_sgd":800000000,"price":8.10,"yield_pct":7.3,"score":38,"score_breakdown":{"sector":22,"mcap":5,"div_vol":5,"payout":0,"price_vol":6},"lot_size":100,"div_history_5y":[0.61,0.59,0.55,0.50,0.45]}
  ]
}
```

- [ ] **Step 2: Verify JSON is valid**

Run: `python -c "import json; json.load(open('assets/bundled_universe.json'))" ` from the project root, or just review visually.

---

## Task 2: Update data models

**Files:**
- Modify: `lib/data/models.dart`
- Modify: `test/data/models_test.dart`

- [ ] **Step 1: Add new fields to Ticker**

In `lib/data/models.dart`, expand the `Ticker` class:

```dart
@immutable
class Ticker {
  final String ticker;
  final String name;
  final String sector;
  final String industry;          // NEW — defaults to sector
  final String description;       // NEW — company blurb
  final double? marketCapSgd;     // NEW — optional market cap in SGD
  final double price;
  final double yieldPct;
  final int score;
  final ScoreBreakdown scoreBreakdown;
  final int lotSize;
  final List<double?> divHistory5y;

  const Ticker({
    required this.ticker,
    required this.name,
    required this.sector,
    this.industry = '',
    this.description = '',
    this.marketCapSgd,
    required this.price,
    required this.yieldPct,
    required this.score,
    required this.scoreBreakdown,
    required this.lotSize,
    required this.divHistory5y,
  });

  factory Ticker.fromJson(Map<String, dynamic> j) => Ticker(
        ticker: j['ticker'] as String,
        name: j['name'] as String,
        sector: j['sector'] as String,
        industry: (j['industry'] as String?) ?? (j['sector'] as String),
        description: (j['description'] as String?) ?? '',
        marketCapSgd: j['market_cap_sgd'] == null
            ? null
            : (j['market_cap_sgd'] as num).toDouble(),
        price: (j['price'] as num).toDouble(),
        yieldPct: (j['yield_pct'] as num).toDouble(),
        score: j['score'] as int,
        scoreBreakdown: ScoreBreakdown.fromJson(
            j['score_breakdown'] as Map<String, dynamic>),
        lotSize: j['lot_size'] as int,
        divHistory5y: (j['div_history_5y'] as List)
            .map((e) => e == null ? null : (e as num).toDouble())
            .toList(),
      );

  double get threeYearCumulativeYieldPct => price > 0
      ? (divHistory5y.take(3).whereType<double>().fold<double>(0, (a, b) => a + b) /
          price *
          100)
      : 0;
}
```

- [ ] **Step 2: Add tests for new fields**

In `test/data/models_test.dart`, add after existing tests:

```dart
  test('Ticker.fromJson uses industry field when present', () {
    final t = Ticker.fromJson({
      'ticker': 'D05',
      'name': 'DBS',
      'sector': 'Banks',
      'industry': 'Banks',
      'description': 'Test description.',
      'market_cap_sgd': 150000000000,
      'price': 42.10,
      'yield_pct': 5.1,
      'score': 18,
      'score_breakdown': {'sector':2,'mcap':0,'div_vol':0,'payout':5,'price_vol':11},
      'lot_size': 100,
      'div_history_5y': [1.92,1.62,1.44,1.20,1.20],
    });
    expect(t.industry, 'Banks');
    expect(t.description, 'Test description.');
    expect(t.marketCapSgd, 150000000000.0);
  });

  test('Ticker.fromJson defaults industry to sector when absent', () {
    final t = Ticker.fromJson({
      'ticker': 'D05',
      'name': 'DBS',
      'sector': 'Banks',
      'price': 42.10,
      'yield_pct': 5.1,
      'score': 18,
      'score_breakdown': {'sector':2,'mcap':0,'div_vol':0,'payout':5,'price_vol':11},
      'lot_size': 100,
      'div_history_5y': [1.92,1.62,1.44,1.20,1.20],
    });
    expect(t.industry, 'Banks');
    expect(t.description, '');
    expect(t.marketCapSgd, isNull);
  });

  test('Ticker.threeYearCumulativeYieldPct computes correctly', () {
    // 3 most-recent divs are index 0,1,2 = 1.92+1.62+1.44 = 4.98
    // price = 42.10 → 4.98/42.10*100 ≈ 11.83%
    final t = Ticker.fromJson({
      'ticker': 'D05', 'name': 'DBS', 'sector': 'Banks',
      'price': 42.10, 'yield_pct': 5.1, 'score': 18,
      'score_breakdown': {'sector':2,'mcap':0,'div_vol':0,'payout':5,'price_vol':11},
      'lot_size': 100,
      'div_history_5y': [1.92, 1.62, 1.44, 1.20, 1.20],
    });
    expect(t.threeYearCumulativeYieldPct, closeTo(11.83, 0.1));
  });
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/data/models_test.dart`
Expected: All pass (3 original + 3 new = 6 tests).

---

## Task 3: Add industry filter to optimizer

**Files:**
- Modify: `lib/domain/optimizer.dart`
- Modify: `test/domain/optimizer_test.dart`

- [ ] **Step 1: Add includedIndustries param to optimize()**

In `lib/domain/optimizer.dart`, change the function signature and add a filter after building `eligible`:

```dart
Allocation optimize({
  required int capitalSgd,
  required RiskLevel risk,
  required Universe universe,
  Set<String>? includedIndustries,
}) {
  if (capitalSgd < _belowMinCapital) {
    return const Allocation(
        lines: [], cashLeftover: 0, totalCapital: 0,
        weightedYieldPct: 0, projectedAnnualIncome: 0);
  }

  final maxScore = risk.maxScore;
  var eligible = universe.tickers.where((t) => t.score <= maxScore).toList()
    ..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));

  if (includedIndustries != null && includedIndustries.isNotEmpty) {
    eligible = eligible.where((t) => includedIndustries.contains(t.industry)).toList();
  }

  // ... rest unchanged
```

- [ ] **Step 2: Update mk() helper in optimizer_test.dart**

Add `industry` parameter to the helper so the new test can set it:

```dart
Ticker mk(String t, {
  String sector = 'Banks',
  String? industry,
  double price = 10.0,
  double yieldPct = 5.0,
  int score = 20,
  int lotSize = 100,
}) => Ticker(
      ticker: t, name: t, sector: sector,
      industry: industry ?? sector,  // defaults to sector
      price: price, yieldPct: yieldPct,
      score: score,
      scoreBreakdown: const ScoreBreakdown(sector: 5, mcap: 0, divVol: 0, payout: 5, priceVol: 10),
      lotSize: lotSize,
      divHistory5y: const [0.5, 0.5, 0.5, 0.5, 0.5],
    );
```

- [ ] **Step 3: Add the industry filter test**

In `test/domain/optimizer_test.dart`, inside the `group('optimizer', ...)` block:

```dart
    test('industry filter excludes specified sectors', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: [
          mk('B1', sector: 'Banks'), mk('R1', sector: 'REITs', score: 35),
          mk('R2', sector: 'REITs', score: 30),
          mk('U1', sector: 'Utilities'), mk('T1', sector: 'Telco'),
          mk('I1', sector: 'Industrials'),
        ],
      );
      final r = optimize(
        capitalSgd: 10000, risk: RiskLevel.aggressive, universe: u,
        includedIndustries: {'Banks', 'REITs'},
      );
      expect(r.lines.every((l) => l.ticker.sector == 'Banks' || l.ticker.sector == 'REITs'), isTrue);
    });
```

- [ ] **Step 4: Run optimizer tests**

Run: `flutter test test/domain/optimizer_test.dart`
Expected: All pass (6 original + 1 new = 7 tests).

---

## Task 4: Create LandingScreen

**Files:**
- Create: `lib/ui/landing_screen.dart`

- [ ] **Step 1: Create landing_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/main_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _enter(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Wordmark
              Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF60A5FA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      'APY',
                      style: GoogleFonts.inter(
                        fontSize: 88,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -4,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Cyan glow underline
                  Container(
                    height: 3,
                    width: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, AppColors.primary, Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Singapore Dividend Yield Simulator',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const Spacer(flex: 4),
              // Enter button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () => _enter(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(200, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: const Text('Enter'),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Task 5: Create MainShell

**Files:**
- Create: `lib/ui/main_shell.dart`

- [ ] **Step 1: Create main_shell.dart**

```dart
import 'package:flutter/material.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/home_tab.dart';
import 'package:sg_dividend/ui/stocks_tab.dart';
import 'package:sg_dividend/ui/optimize_tab.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void switchToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: const [
          HomeTab(),
          StocksTab(),
          OptimizeTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            label: 'Stocks',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: AppColors.primary),
            label: 'Optimize',
          ),
        ],
      ),
    );
  }
}
```

---

## Task 6: Create HomeTab

**Files:**
- Create: `lib/ui/home_tab.dart`

- [ ] **Step 1: Create home_tab.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/main_shell.dart';
import 'package:sg_dividend/ui/splash_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('APY')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) => _HomeContent(universe: u),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Universe universe;
  const _HomeContent({required this.universe});

  @override
  Widget build(BuildContext context) {
    final tickers = universe.tickers;
    final avgYield = tickers.isEmpty
        ? 0.0
        : tickers.fold<double>(0, (s, t) => s + t.yieldPct) / tickers.length;
    final topYielder = tickers.isEmpty
        ? null
        : tickers.reduce((a, b) => a.yieldPct > b.yieldPct ? a : b);

    // Sector breakdown
    final sectorCounts = <String, int>{};
    for (final t in tickers) {
      sectorCounts[t.sector] = (sectorCounts[t.sector] ?? 0) + 1;
    }

    // Score distribution
    final conservative = tickers.where((t) => t.score <= 35).length;
    final neutral = tickers.where((t) => t.score > 35 && t.score <= 60).length;
    final aggressive = tickers.where((t) => t.score > 60).length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Hero card
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Label('UNIVERSE'),
            const SizedBox(height: 12),
            Text(
              '${tickers.length} SGX dividend stocks tracked',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Average yield: ${avgYield.toStringAsFixed(2)}% p.a.',
              style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Top yielder
        if (topYielder != null) ...[
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Label('TOP YIELDER'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(topYielder.ticker,
                        style: GoogleFonts.inter(
                            color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800,
                            fontFeatures: [const FontFeature.tabularFigures()])),
                    const SizedBox(height: 2),
                    Text(topYielder.name,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(topYielder.sector,
                        style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${topYielder.yieldPct.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                          color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w900)),
                  Text('yield p.a.',
                      style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                ]),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Sector breakdown
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Label('SECTOR BREAKDOWN'),
            const SizedBox(height: 16),
            ...sectorCounts.entries.map((e) {
              final fraction = e.value / tickers.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e.key,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13))),
                    Text('${e.value}',
                        style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ]),
              );
            }),
          ]),
        ),
        const SizedBox(height: 16),

        // Score distribution
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Label('RISK SCORE DISTRIBUTION'),
            const SizedBox(height: 16),
            _ScoreBar(label: 'Conservative (≤35)', count: conservative, total: tickers.length, color: AppColors.secondary),
            const SizedBox(height: 8),
            _ScoreBar(label: 'Neutral (36–60)', count: neutral, total: tickers.length, color: AppColors.chartAmber),
            const SizedBox(height: 8),
            _ScoreBar(label: 'Aggressive (61–100)', count: aggressive, total: tickers.length, color: AppColors.error),
          ]),
        ),
        const SizedBox(height: 24),

        // Quick Optimize CTA
        FilledButton.icon(
          onPressed: () {
            final shell = context.findAncestorStateOfType<MainShellState>();
            shell?.switchToTab(2);
          },
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Quick Optimize'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/disclaimer'),
            child: Text('Disclaimer',
                style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _ScoreBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12))),
        Text('$count', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 6,
          backgroundColor: AppColors.surfaceElevated,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0));
  }
}
```

---

## Task 7: Create StocksTab + StockDetailScreen

**Files:**
- Create: `lib/ui/stocks_tab.dart`
- Create: `lib/ui/stock_detail_screen.dart`

- [ ] **Step 1: Create stocks_tab.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/splash_screen.dart';
import 'package:sg_dividend/ui/stock_detail_screen.dart';

enum _SortMode { yieldDesc, scoreAsc, alpha }

class StocksTab extends ConsumerStatefulWidget {
  const StocksTab({super.key});

  @override
  ConsumerState<StocksTab> createState() => _StocksTabState();
}

class _StocksTabState extends ConsumerState<StocksTab> {
  _SortMode _sort = _SortMode.yieldDesc;

  List<Ticker> _sorted(List<Ticker> tickers) {
    final list = [...tickers];
    switch (_sort) {
      case _SortMode.yieldDesc:
        list.sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
      case _SortMode.scoreAsc:
        list.sort((a, b) => a.score.compareTo(b.score));
      case _SortMode.alpha:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stocks'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<_SortMode>(
              value: _sort,
              dropdownColor: AppColors.surfaceElevated,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary, size: 20),
              items: const [
                DropdownMenuItem(value: _SortMode.yieldDesc, child: Text('Yield ↓')),
                DropdownMenuItem(value: _SortMode.scoreAsc, child: Text('Score ↑')),
                DropdownMenuItem(value: _SortMode.alpha, child: Text('A–Z')),
              ],
              onChanged: (v) => setState(() => _sort = v!),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) {
          final sorted = _sorted(u.tickers);
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1, thickness: 1, color: AppColors.border, indent: 16, endIndent: 16),
            itemBuilder: (context, i) {
              final t = sorted[i];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StockDetailScreen(ticker: t)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    // Ticker code
                    SizedBox(
                      width: 52,
                      child: Text(
                        t.ticker,
                        style: GoogleFonts.sourceCodePro(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + sector
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.name,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(t.sector,
                            style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    // Price + 3y yield
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('S\$${t.price.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${t.threeYearCumulativeYieldPct.toStringAsFixed(1)}% 3y',
                          style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Create stock_detail_screen.dart**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';

class StockDetailScreen extends StatelessWidget {
  final Ticker ticker;
  const StockDetailScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    final t = ticker;
    final fmt = NumberFormat.compactCurrency(locale: 'en_SG', symbol: 'S\$');
    final currentYear = DateTime.now().year;

    // Build bar chart data from div history
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < t.divHistory5y.length; i++) {
      final val = t.divHistory5y[i];
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val ?? 0,
            color: val == null ? AppColors.textTertiary : AppColors.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    // Score component bars
    final scoreComponents = [
      ('Sector', t.scoreBreakdown.sector, 30),
      ('Mkt Cap', t.scoreBreakdown.mcap, 10),
      ('Div Vol', t.scoreBreakdown.divVol, 20),
      ('Payout', t.scoreBreakdown.payout, 20),
      ('Price Vol', t.scoreBreakdown.priceVol, 20),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${t.ticker} · ${t.name}', overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  'S\$${t.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${t.yieldPct.toStringAsFixed(2)}% yield',
                      style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(t.sector,
                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Company
          if (t.description.isNotEmpty) ...[
            _SectionLabel('COMPANY'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(t.description,
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            ),
            const SizedBox(height: 20),
          ],

          // Market data
          _SectionLabel('MARKET DATA'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              if (t.marketCapSgd != null) ...[
                _DataRow('Market Cap', fmt.format(t.marketCapSgd)),
                const Divider(height: 16, color: AppColors.border),
              ],
              _DataRow('Lot Size', '${t.lotSize} shares'),
              const Divider(height: 16, color: AppColors.border),
              _DataRow('Risk Score', '${t.score} / 100'),
            ]),
          ),
          const SizedBox(height: 20),

          // Dividend history
          _SectionLabel('5-YEAR DIVIDEND HISTORY'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.border,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final year = currentYear - t.divHistory5y.length + 1 + value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('$year',
                                style: GoogleFonts.inter(
                                    color: AppColors.textTertiary, fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Risk score breakdown
          _SectionLabel('RISK SCORE BREAKDOWN'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: scoreComponents.asMap().entries.map((entry) {
                final (label, value, max) = entry.value;
                final fraction = max > 0 ? value / max : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(label,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13))),
                      Text('$value / $max',
                          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fraction > 0.7 ? AppColors.error : fraction > 0.4 ? AppColors.chartAmber : AppColors.secondary,
                        ),
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0));
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}
```

---

## Task 8: Create OptimizeTab

**Files:**
- Create: `lib/ui/optimize_tab.dart`

- [ ] **Step 1: Create optimize_tab.dart**

This is the InputScreen content reimplemented as a tab, with an industry filter section added above the Optimize button.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/result_screen.dart';
import 'package:sg_dividend/ui/splash_screen.dart';

const _kAllIndustries = ['Banks', 'REITs', 'Telco', 'Utilities', 'Industrials', 'Consumer', 'Business Trusts', 'Other'];

class OptimizeTab extends ConsumerStatefulWidget {
  const OptimizeTab({super.key});

  @override
  ConsumerState<OptimizeTab> createState() => _OptimizeTabState();
}

class _OptimizeTabState extends ConsumerState<OptimizeTab> {
  final _capitalCtrl = TextEditingController(text: '10000');
  final _monthlyCtrl = TextEditingController(text: '0');
  RiskLevel _risk = RiskLevel.neutral;
  int _horizon = 5;
  bool _drip = true;
  final Set<String> _selectedIndustries = Set.from(_kAllIndustries);

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Optimize')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (universe) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _InputCard(
              label: 'CAPITAL',
              child: TextField(
                controller: _capitalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  prefixText: 'S\$ ',
                  prefixStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: '10000',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'RISK LEVEL',
              child: SegmentedButton<RiskLevel>(
                segments: const [
                  ButtonSegment(value: RiskLevel.conservative, label: Text('Conservative')),
                  ButtonSegment(value: RiskLevel.neutral, label: Text('Neutral')),
                  ButtonSegment(value: RiskLevel.aggressive, label: Text('Aggressive')),
                ],
                selected: {_risk},
                onSelectionChanged: (s) => setState(() => _risk = s.first),
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'HORIZON (YEARS)',
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1y')),
                  ButtonSegment(value: 5, label: Text('5y')),
                  ButtonSegment(value: 10, label: Text('10y')),
                  ButtonSegment(value: 20, label: Text('20y')),
                ],
                selected: {_horizon},
                onSelectionChanged: (s) => setState(() => _horizon = s.first),
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'DRIP',
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Reinvest dividends',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Compound returns by reinvesting payouts',
                          style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                    ]),
                  ),
                  Switch(value: _drip, onChanged: (v) => setState(() => _drip = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'MONTHLY CONTRIBUTION',
              child: TextField(
                controller: _monthlyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  prefixText: 'S\$ ',
                  prefixStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: '0 (optional)',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Industry filter
            _InputCard(
              label: 'INDUSTRIES (OPTIONAL)',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Include only selected sectors in the portfolio:',
                    style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kAllIndustries.map((ind) {
                    final selected = _selectedIndustries.contains(ind);
                    return FilterChip(
                      label: Text(ind),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedIndustries.add(ind);
                          } else {
                            _selectedIndustries.remove(ind);
                          }
                        });
                      },
                      labelStyle: GoogleFonts.inter(
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      side: BorderSide(
                        color: selected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    onPressed: () => setState(() => _selectedIndustries.addAll(_kAllIndustries)),
                    child: Text('All', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    onPressed: () => setState(() => _selectedIndustries.clear()),
                    child: Text('None', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 32),

            // Optimize button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  final cap = int.tryParse(_capitalCtrl.text) ?? 0;
                  final monthly = int.tryParse(_monthlyCtrl.text) ?? 0;
                  // Pass null if all selected (no filtering), else pass the set
                  final filter = _selectedIndustries.length == _kAllIndustries.length
                      ? null
                      : Set<String>.from(_selectedIndustries);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      universe: universe,
                      capital: cap,
                      risk: _risk,
                      horizonYears: _horizon,
                      drip: _drip,
                      monthlySgd: monthly,
                      includedIndustries: filter,
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('Optimize Portfolio',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InputCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
```

---

## Task 9: Update ResultScreen to accept includedIndustries

**Files:**
- Modify: `lib/ui/result_screen.dart`

- [ ] **Step 1: Add includedIndustries param to ResultScreen**

Add optional `Set<String>? includedIndustries` field and pass it to `optimize()`:

In ResultScreen class:
```dart
class ResultScreen extends StatelessWidget {
  final Universe universe;
  final int capital;
  final RiskLevel risk;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;
  final Set<String>? includedIndustries;  // NEW

  const ResultScreen({
    super.key,
    required this.universe,
    required this.capital,
    required this.risk,
    required this.horizonYears,
    required this.drip,
    required this.monthlySgd,
    this.includedIndustries,             // NEW
  });
```

In the build method, change the optimize call:
```dart
final alloc = optimize(
    capitalSgd: capital, risk: risk, universe: universe,
    includedIndustries: includedIndustries);
```

---

## Task 10: Update SplashScreen and App

**Files:**
- Modify: `lib/ui/splash_screen.dart`
- Modify: `lib/app.dart`
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: SplashScreen → LandingScreen after load**

In `lib/ui/splash_screen.dart`, replace `data: (u) => InputScreen(universe: u),` with:
```dart
data: (u) {
  // Navigate to LandingScreen after universe is loaded
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    }
  });
  return const SizedBox.shrink();
},
```

And update imports to remove InputScreen and add LandingScreen.

- [ ] **Step 2: app.dart title**

Change `title: 'SG Dividend Optimizer'` to `title: 'APY'`.

- [ ] **Step 3: pubspec.yaml description**

Change `description: Singapore dividend portfolio optimizer (educational).` to `description: APY — Singapore dividend yield optimizer.`

- [ ] **Step 4: iOS Info.plist**

Change `CFBundleDisplayName` to `APY` and `CFBundleName` to `APY`.

- [ ] **Step 5: AndroidManifest.xml**

Change `android:label="sg_dividend"` to `android:label="APY"`.

---

## Task 11: Wire disclaimer route + fix imports

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Add disclaimer named route to MaterialApp**

Add `routes` to the MaterialApp:
```dart
routes: {
  '/disclaimer': (_) => const DisclaimerScreen(),
},
```

And import `package:sg_dividend/ui/disclaimer_screen.dart`.

---

## Task 12: Run analyze + test

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors (warnings/hints acceptable).

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: All tests pass (16 original + 4 new = 20 tests).

- [ ] **Step 3: Fix any issues found**

If analyze/tests fail, fix issues and re-run.

---

## Task 13: Commit and push

- [ ] **Step 1: Commit**

```bash
git add -A
git commit -m "feat(app): APY multi-tab restructure (landing + home + stocks + optimize)"
```

- [ ] **Step 2: Push**

```bash
git push origin main
```

---

## Self-Review: Spec Coverage Check

- App rename to APY → covered Task 10
- Landing screen with wordmark + Enter → Task 4
- Home tab with dashboard cards → Task 6
- Stocks tab with list + sort → Task 7 (stocks_tab.dart)
- Stock Detail screen → Task 7 (stock_detail_screen.dart)
- Optimize tab with industry filter chips → Task 8
- ResultScreen accepts includedIndustries → Task 9
- SplashScreen → LandingScreen → MainShell flow → Task 10
- Bundled JSON enriched → Task 1
- Model fields: description, industry, marketCapSgd, threeYearCumulativeYieldPct → Task 2
- Optimizer industry filter param → Task 3
- Industry filter test → Task 3
- Models new-field tests → Task 2
- All 16 original tests preserved → mk() helper is additive only
- Bundle ID NOT changed → correct, not touched
- Pendle dark theme unchanged → only new screens use it, theme.dart untouched
- Disclaimer link in Home tab footer → Task 6 (TextButton navigates to /disclaimer)
- Named route for /disclaimer → Task 11
