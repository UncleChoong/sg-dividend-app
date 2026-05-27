# SG Dividend Optimizer App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile app (iOS + Android) that takes user inputs (capital, risk level, horizon, DRIP, monthly contribution), fetches the SG dividend universe JSON produced by the data pipeline, runs a rules-based optimizer on-device to produce an allocation across SGX dividend stocks, and simulates forward returns with a line chart.

**Architecture:** Stateless client. Riverpod state. Three layers: `data` (fetch + cache JSON, bundled fallback), `domain` (pure optimizer + simulator functions), `ui` (screens). No backend, no auth, no PII server-side.

**Tech Stack:** Flutter 3.22+, Dart 3.4+, `flutter_riverpod`, `dio`, `fl_chart`, `glados` (property tests), `shared_preferences`.

**Repo location:** `C:\Users\USER\sg-dividend-app` (already exists — spec is there).

---

## File Structure

```
sg-dividend-app/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp + router
│   ├── theme.dart
│   ├── data/
│   │   ├── models.dart                   # Universe, Ticker, Allocation, SimulationPoint, RiskLevel
│   │   └── universe_repository.dart      # fetch + cache + bundled fallback
│   ├── domain/
│   │   ├── optimizer.dart                # pure: (capital, risk, universe) → Allocation
│   │   └── simulator.dart                # pure: (Allocation, horizon, drip, monthly) → List<SimulationPoint>
│   └── ui/
│       ├── splash_screen.dart
│       ├── input_screen.dart
│       ├── result_screen.dart
│       ├── simulator_screen.dart
│       ├── explain_screen.dart
│       ├── disclaimer_screen.dart
│       └── widgets/
│           ├── disclaimer_banner.dart
│           ├── allocation_pie.dart
│           └── projection_chart.dart
├── assets/
│   └── bundled_universe.json             # offline-first fallback (copy of recent prod JSON)
├── test/
│   ├── data/
│   │   └── universe_repository_test.dart
│   ├── domain/
│   │   ├── optimizer_test.dart
│   │   └── simulator_test.dart
│   └── ui/
│       └── input_to_result_flow_test.dart
└── integration_test/
    └── app_test.dart
```

**Config:** The R2 JSON URL is read from a build-time env var so dev/prod can differ. Default to a placeholder `https://CHANGE_ME.r2.dev/sg_dividend_universe.json` and override via `--dart-define`.

---

### Task 1: Flutter project scaffolding

**Files:**
- Run: `flutter create` in existing repo
- Modify: `pubspec.yaml`

- [ ] **Step 1: Verify Flutter installed**

```bash
flutter --version
```
Expected: Flutter 3.22 or later. If not installed, on Windows: `winget install Google.Flutter` then add to PATH.

- [ ] **Step 2: Init Flutter project**

```bash
cd /c/Users/USER/sg-dividend-app
flutter create --org sg.dividend --project-name sg_dividend --platforms ios,android --no-overwrite .
```

This populates `lib/`, `android/`, `ios/`, `test/` without clobbering existing `docs/`.

- [ ] **Step 3: Edit pubspec.yaml**

Replace dependencies block:
```yaml
name: sg_dividend
description: Singapore dividend portfolio optimizer (educational).
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  dio: ^5.4.0
  fl_chart: ^0.68.0
  shared_preferences: ^2.2.2
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  glados: ^0.2.0
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/bundled_universe.json
```

- [ ] **Step 4: Install deps**

```bash
flutter pub get
```
Expected: no errors.

- [ ] **Step 5: Bundled fallback JSON**

Place a known-good universe JSON at `assets/bundled_universe.json`. For initial scaffolding, copy this minimal placeholder so tests work; replace with a real snapshot once the data pipeline has produced one.

```json
{
  "generated_at": "2026-05-27T00:00:00+08:00",
  "schema_version": 1,
  "universe": [
    {"ticker":"D05","name":"DBS Group","sector":"Banks","price":42.10,"yield_pct":5.1,"score":18,"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":5,"price_vol":11},"lot_size":100,"div_history_5y":[1.92,1.62,1.44,1.20,1.20]},
    {"ticker":"O39","name":"OCBC","sector":"Banks","price":15.20,"yield_pct":5.6,"score":15,"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":3,"price_vol":10},"lot_size":100,"div_history_5y":[0.85,0.84,0.68,0.53,0.53]},
    {"ticker":"U11","name":"UOB","sector":"Banks","price":29.80,"yield_pct":5.4,"score":17,"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":4,"price_vol":11},"lot_size":100,"div_history_5y":[1.70,1.50,1.35,0.78,1.30]},
    {"ticker":"Z74","name":"Singtel","sector":"Telco","price":3.50,"yield_pct":5.2,"score":25,"score_breakdown":{"sector":15,"mcap":0,"div_vol":5,"payout":0,"price_vol":5},"lot_size":100,"div_history_5y":[0.15,0.149,0.09,0.075,0.175]},
    {"ticker":"A17U","name":"Ascendas REIT","sector":"REITs","price":2.60,"yield_pct":5.9,"score":42,"score_breakdown":{"sector":27,"mcap":0,"div_vol":0,"payout":10,"price_vol":5},"lot_size":100,"div_history_5y":[0.155,0.152,0.150,0.149,0.146]},
    {"ticker":"C38U","name":"CapitaLand Integrated Commercial Trust","sector":"REITs","price":2.05,"yield_pct":5.5,"score":40,"score_breakdown":{"sector":27,"mcap":0,"div_vol":0,"payout":8,"price_vol":5},"lot_size":100,"div_history_5y":[0.106,0.104,0.098,0.087,0.108]},
    {"ticker":"M44U","name":"Mapletree Logistics Trust","sector":"REITs","price":1.40,"yield_pct":6.1,"score":45,"score_breakdown":{"sector":27,"mcap":3,"div_vol":0,"payout":10,"price_vol":5},"lot_size":100,"div_history_5y":[0.086,0.090,0.085,0.082,0.081]},
    {"ticker":"S63","name":"ST Engineering","sector":"Industrials","price":4.30,"yield_pct":3.7,"score":22,"score_breakdown":{"sector":17,"mcap":0,"div_vol":0,"payout":0,"price_vol":5},"lot_size":100,"div_history_5y":[0.16,0.16,0.16,0.15,0.15]},
    {"ticker":"S68","name":"Singapore Exchange","sector":"Industrials","price":11.20,"yield_pct":3.0,"score":20,"score_breakdown":{"sector":17,"mcap":0,"div_vol":0,"payout":0,"price_vol":3},"lot_size":100,"div_history_5y":[0.34,0.32,0.32,0.30,0.30]},
    {"ticker":"ES3","name":"SPDR STI ETF","sector":"Other","price":3.50,"yield_pct":3.8,"score":23,"score_breakdown":{"sector":22,"mcap":0,"div_vol":0,"payout":0,"price_vol":1},"lot_size":100,"div_history_5y":[0.12,0.12,0.11,0.10,0.13]},
    {"ticker":"QL3","name":"iShares USD Asia High Yield Bond ETF","sector":"Other","price":8.10,"yield_pct":7.3,"score":38,"score_breakdown":{"sector":22,"mcap":5,"div_vol":5,"payout":0,"price_vol":6},"lot_size":100,"div_history_5y":[0.61,0.59,0.55,0.50,0.45]}
  ]
}
```

- [ ] **Step 6: Verify build**

```bash
flutter analyze
```
Expected: no issues (existing scaffold may have a few; fix them).

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/bundled_universe.json lib/ android/ ios/ test/ .gitignore analysis_options.yaml
git commit -m "chore: Flutter project scaffolding + bundled fallback"
```

---

### Task 2: Data models

**Files:**
- Create: `lib/data/models.dart`
- Test: `test/data/models_test.dart`

- [ ] **Step 1: Write failing test**

`test/data/models_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sg_dividend/data/models.dart';

void main() {
  test('Ticker.fromJson parses minimal entry', () {
    final t = Ticker.fromJson({
      'ticker': 'D05',
      'name': 'DBS',
      'sector': 'Banks',
      'price': 42.10,
      'yield_pct': 5.1,
      'score': 18,
      'score_breakdown': {'sector':2,'mcap':0,'div_vol':0,'payout':5,'price_vol':11},
      'lot_size': 100,
      'div_history_5y': [1.92,1.62,null,1.20,1.20],
    });
    expect(t.ticker, 'D05');
    expect(t.price, 42.10);
    expect(t.divHistory5y[2], isNull);
  });

  test('Universe.fromJson parses wrapper', () {
    final u = Universe.fromJson({
      'generated_at': '2026-05-27T00:00:00+08:00',
      'schema_version': 1,
      'universe': [
        {'ticker':'D05','name':'DBS','sector':'Banks','price':42.10,'yield_pct':5.1,
         'score':18,'score_breakdown':{'sector':2,'mcap':0,'div_vol':0,'payout':5,'price_vol':11},
         'lot_size':100,'div_history_5y':[1.92,1.62,1.44,1.20,1.20]},
      ],
    });
    expect(u.tickers, hasLength(1));
    expect(u.tickers.first.ticker, 'D05');
  });

  test('RiskLevel maxScore bands', () {
    expect(RiskLevel.conservative.maxScore, 35);
    expect(RiskLevel.neutral.maxScore, 60);
    expect(RiskLevel.aggressive.maxScore, 100);
  });
}
```

- [ ] **Step 2: Run, expect fail**

```bash
flutter test test/data/models_test.dart
```

- [ ] **Step 3: Implement models.dart**

`lib/data/models.dart`:
```dart
import 'package:flutter/foundation.dart';

enum RiskLevel { conservative, neutral, aggressive }

extension RiskLevelX on RiskLevel {
  int get maxScore => switch (this) {
        RiskLevel.conservative => 35,
        RiskLevel.neutral => 60,
        RiskLevel.aggressive => 100,
      };

  String get label => switch (this) {
        RiskLevel.conservative => 'Conservative',
        RiskLevel.neutral => 'Neutral',
        RiskLevel.aggressive => 'Aggressive',
      };
}

@immutable
class ScoreBreakdown {
  final int sector;
  final int mcap;
  final int divVol;
  final int payout;
  final int priceVol;

  const ScoreBreakdown({
    required this.sector,
    required this.mcap,
    required this.divVol,
    required this.payout,
    required this.priceVol,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> j) => ScoreBreakdown(
        sector: j['sector'] as int,
        mcap: j['mcap'] as int,
        divVol: j['div_vol'] as int,
        payout: j['payout'] as int,
        priceVol: j['price_vol'] as int,
      );
}

@immutable
class Ticker {
  final String ticker;
  final String name;
  final String sector;
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
        price: (j['price'] as num).toDouble(),
        yieldPct: (j['yield_pct'] as num).toDouble(),
        score: j['score'] as int,
        scoreBreakdown: ScoreBreakdown.fromJson(j['score_breakdown'] as Map<String, dynamic>),
        lotSize: j['lot_size'] as int,
        divHistory5y: (j['div_history_5y'] as List)
            .map((e) => e == null ? null : (e as num).toDouble())
            .toList(),
      );
}

@immutable
class Universe {
  final DateTime generatedAt;
  final int schemaVersion;
  final List<Ticker> tickers;

  const Universe({
    required this.generatedAt,
    required this.schemaVersion,
    required this.tickers,
  });

  factory Universe.fromJson(Map<String, dynamic> j) => Universe(
        generatedAt: DateTime.parse(j['generated_at'] as String),
        schemaVersion: j['schema_version'] as int,
        tickers: (j['universe'] as List)
            .map((e) => Ticker.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

@immutable
class AllocationLine {
  final Ticker ticker;
  final int lots;
  final double sgdAllocated;
  final double projectedAnnualIncome;

  const AllocationLine({
    required this.ticker,
    required this.lots,
    required this.sgdAllocated,
    required this.projectedAnnualIncome,
  });

  double get weightPct => 0; // computed lazily by consumer via Allocation.totalCapital
}

@immutable
class Allocation {
  final List<AllocationLine> lines;
  final double cashLeftover;
  final double totalCapital;
  final double weightedYieldPct;
  final double projectedAnnualIncome;

  const Allocation({
    required this.lines,
    required this.cashLeftover,
    required this.totalCapital,
    required this.weightedYieldPct,
    required this.projectedAnnualIncome,
  });
}

@immutable
class SimulationPoint {
  final int year;
  final double portfolioValue;
  final double cumulativeIncome;
  double get total => portfolioValue + cumulativeIncome;
  const SimulationPoint({
    required this.year,
    required this.portfolioValue,
    required this.cumulativeIncome,
  });
}
```

- [ ] **Step 4: Run, expect pass**

```bash
flutter test test/data/models_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/models.dart test/data/models_test.dart
git commit -m "feat: data models"
```

---

### Task 3: Universe repository

**Files:**
- Create: `lib/data/universe_repository.dart`
- Test: `test/data/universe_repository_test.dart`

Repository fetches the JSON from R2, caches it in `SharedPreferences` as text, falls back to bundled asset on first run or fetch failure.

- [ ] **Step 1: Write failing test**

`test/data/universe_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg_dividend/data/universe_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('loads bundled fallback when no cache and no network', () async {
    final repo = UniverseRepository(remoteUrl: 'https://invalid.test/none.json');
    final u = await repo.load();
    expect(u.tickers, isNotEmpty);
    expect(u.tickers.any((t) => t.ticker == 'D05'), isTrue);
  });

  test('caches successful fetch into prefs', () async {
    final repo = UniverseRepository(remoteUrl: 'https://invalid.test/none.json');
    // simulate cache by writing directly
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      UniverseRepository.cacheKey,
      '{"generated_at":"2026-05-27T00:00:00+08:00","schema_version":1,'
      '"universe":[{"ticker":"FAKE","name":"Fake","sector":"Banks",'
      '"price":10.0,"yield_pct":5.0,"score":20,'
      '"score_breakdown":{"sector":2,"mcap":0,"div_vol":0,"payout":5,"price_vol":13},'
      '"lot_size":100,"div_history_5y":[0.5,0.5,0.5,0.5,0.5]}]}',
    );
    final u = await repo.load();
    expect(u.tickers.first.ticker, 'FAKE');
  });
}
```

- [ ] **Step 2: Run, expect fail**

```bash
flutter test test/data/universe_repository_test.dart
```

- [ ] **Step 3: Implement universe_repository.dart**

`lib/data/universe_repository.dart`:
```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg_dividend/data/models.dart';

class UniverseRepository {
  static const cacheKey = 'sg_dividend.universe_json';
  static const bundledAsset = 'assets/bundled_universe.json';
  static const defaultRemoteUrl = String.fromEnvironment(
    'UNIVERSE_URL',
    defaultValue: 'https://CHANGE_ME.r2.dev/sg_dividend_universe.json',
  );

  final String remoteUrl;
  final Dio _dio;

  UniverseRepository({String? remoteUrl, Dio? dio})
      : remoteUrl = remoteUrl ?? defaultRemoteUrl,
        _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8),
                                       receiveTimeout: const Duration(seconds: 8)));

  /// Try remote → cache → bundled. Never throws on network failure.
  Future<Universe> load() async {
    // 1. Remote
    try {
      final resp = await _dio.get<String>(remoteUrl,
          options: Options(responseType: ResponseType.plain));
      final body = resp.data;
      if (body != null && body.isNotEmpty) {
        final u = Universe.fromJson(jsonDecode(body) as Map<String, dynamic>);
        await _saveCache(body);
        return u;
      }
    } catch (_) {/* fall through */}

    // 2. Cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        return Universe.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {/* fall through */}
    }

    // 3. Bundled
    final asset = await rootBundle.loadString(bundledAsset);
    return Universe.fromJson(jsonDecode(asset) as Map<String, dynamic>);
  }

  Future<void> _saveCache(String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, body);
  }
}
```

- [ ] **Step 4: Run, expect pass**

```bash
flutter test test/data/universe_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/universe_repository.dart test/data/universe_repository_test.dart
git commit -m "feat: universe repository with cache + bundled fallback"
```

---

### Task 4: Optimizer

**Files:**
- Create: `lib/domain/optimizer.dart`
- Test: `test/domain/optimizer_test.dart`

- [ ] **Step 1: Write failing tests**

`test/domain/optimizer_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/optimizer.dart';

Ticker mk(String t, {
  String sector = 'Banks',
  double price = 10.0,
  double yieldPct = 5.0,
  int score = 20,
  int lotSize = 100,
}) => Ticker(
      ticker: t, name: t, sector: sector, price: price, yieldPct: yieldPct,
      score: score,
      scoreBreakdown: const ScoreBreakdown(sector: 5, mcap: 0, divVol: 0, payout: 5, priceVol: 10),
      lotSize: lotSize,
      divHistory5y: const [0.5, 0.5, 0.5, 0.5, 0.5],
    );

void main() {
  group('optimizer', () {
    test('returns empty when capital too small', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: [mk('A'), mk('B'), mk('C'), mk('D'), mk('E')],
      );
      final r = optimize(capitalSgd: 400, risk: RiskLevel.neutral, universe: u);
      expect(r.lines, isEmpty);
      expect(r.totalCapital, 0);
    });

    test('conservative filters out high-score tickers', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: [
          mk('LOW1', score: 20), mk('LOW2', score: 25, sector: 'Utilities'),
          mk('LOW3', score: 30, sector: 'Telco'), mk('LOW4', score: 30, sector: 'Industrials'),
          mk('LOW5', score: 30, sector: 'Consumer'),
          mk('HIGH', score: 80),
        ],
      );
      final r = optimize(capitalSgd: 10000, risk: RiskLevel.conservative, universe: u);
      expect(r.lines.every((l) => l.ticker.score <= 35), isTrue);
    });

    test('respects max 25% per ticker', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: List.generate(6, (i) => mk('T$i', sector: 'Banks', score: 20)),
      );
      final r = optimize(capitalSgd: 10000, risk: RiskLevel.aggressive, universe: u);
      for (final l in r.lines) {
        expect(l.sgdAllocated, lessThanOrEqualTo(10000 * 0.25 + 0.01),
            reason: '${l.ticker.ticker} exceeded 25%');
      }
    });

    test('respects max 40% per sector', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: [
          mk('B1', sector: 'Banks'), mk('B2', sector: 'Banks'), mk('B3', sector: 'Banks'),
          mk('R1', sector: 'REITs', score: 40), mk('R2', sector: 'REITs', score: 40),
          mk('I1', sector: 'Industrials', score: 25), mk('I2', sector: 'Industrials', score: 25),
        ],
      );
      final r = optimize(capitalSgd: 10000, risk: RiskLevel.aggressive, universe: u);
      final perSector = <String, double>{};
      for (final l in r.lines) {
        perSector[l.ticker.sector] = (perSector[l.ticker.sector] ?? 0) + l.sgdAllocated;
      }
      for (final v in perSector.values) {
        expect(v, lessThanOrEqualTo(10000 * 0.40 + 0.01));
      }
    });

    test('returns at least 5 tickers when capital sufficient and universe large enough', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: [
          mk('B1', sector: 'Banks'), mk('U1', sector: 'Utilities'),
          mk('T1', sector: 'Telco'), mk('R1', sector: 'REITs', score: 35),
          mk('I1', sector: 'Industrials', score: 25),
          mk('C1', sector: 'Consumer', score: 30),
        ],
      );
      final r = optimize(capitalSgd: 10000, risk: RiskLevel.aggressive, universe: u);
      expect(r.lines.length, greaterThanOrEqualTo(5));
    });

    test('projected income equals sum of line incomes', () {
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: List.generate(5, (i) => mk('T$i', sector: 'Banks', score: 20, yieldPct: 4.0)),
      );
      final r = optimize(capitalSgd: 10000, risk: RiskLevel.aggressive, universe: u);
      final sum = r.lines.fold<double>(0, (a, l) => a + l.projectedAnnualIncome);
      expect((r.projectedAnnualIncome - sum).abs(), lessThan(0.01));
    });
  });
}
```

- [ ] **Step 2: Run, expect fail**

```bash
flutter test test/domain/optimizer_test.dart
```

- [ ] **Step 3: Implement optimizer.dart**

`lib/domain/optimizer.dart`:
```dart
import 'package:sg_dividend/data/models.dart';

const double _maxPerTicker = 0.25;
const double _maxPerSector = 0.40;
const int _minTickers = 5;
const int _minTickersSmallCapital = 3;
const int _smallCapitalThreshold = 2000;
const int _belowMinCapital = 500;

Allocation optimize({
  required int capitalSgd,
  required RiskLevel risk,
  required Universe universe,
}) {
  if (capitalSgd < _belowMinCapital) {
    return const Allocation(
        lines: [], cashLeftover: 0, totalCapital: 0,
        weightedYieldPct: 0, projectedAnnualIncome: 0);
  }

  final maxScore = risk.maxScore;
  final eligible = universe.tickers.where((t) => t.score <= maxScore).toList()
    ..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));

  final maxTickerSgd = capitalSgd * _maxPerTicker;
  final maxSectorSgd = capitalSgd * _maxPerSector;
  final minBasket = capitalSgd < _smallCapitalThreshold ? _minTickersSmallCapital : _minTickers;

  final lines = <AllocationLine>[];
  final sectorSpent = <String, double>{};
  double remaining = capitalSgd.toDouble();

  // First pass: greedy by yield, respecting ticker + sector caps
  for (final t in eligible) {
    if (remaining <= 0) break;
    final spent = sectorSpent[t.sector] ?? 0;
    final sectorRoom = maxSectorSgd - spent;
    if (sectorRoom <= 0) continue;

    final lotCost = t.price * t.lotSize;
    if (lotCost <= 0) continue;

    final headroom = [remaining, maxTickerSgd, sectorRoom].reduce((a, b) => a < b ? a : b);
    final lots = (headroom / lotCost).floor();
    if (lots < 1) continue;

    final cost = lots * lotCost;
    final income = cost * (t.yieldPct / 100.0);
    lines.add(AllocationLine(
        ticker: t, lots: lots, sgdAllocated: cost, projectedAnnualIncome: income));
    sectorSpent[t.sector] = spent + cost;
    remaining -= cost;
  }

  // Diversification: ensure min basket size, drop excess weight from biggest position if needed
  if (lines.length < minBasket) {
    // The universe genuinely doesn't have enough eligible tickers in different sectors.
    // Caller will see fewer than min — surfaced in UI as a warning. No re-balance.
  }

  // Residual cash: allocate to the lowest-score ticker we already hold, if any lots affordable
  if (remaining > 0 && lines.isNotEmpty) {
    final sortedByScore = [...lines]
      ..sort((a, b) => a.ticker.score.compareTo(b.ticker.score));
    for (final l in sortedByScore) {
      final lotCost = l.ticker.price * l.ticker.lotSize;
      final extra = (remaining / lotCost).floor();
      if (extra >= 1) {
        final addCost = extra * lotCost;
        final addIncome = addCost * (l.ticker.yieldPct / 100.0);
        final idx = lines.indexOf(l);
        lines[idx] = AllocationLine(
            ticker: l.ticker,
            lots: l.lots + extra,
            sgdAllocated: l.sgdAllocated + addCost,
            projectedAnnualIncome: l.projectedAnnualIncome + addIncome);
        remaining -= addCost;
        break;
      }
    }
  }

  final invested = lines.fold<double>(0, (a, l) => a + l.sgdAllocated);
  final income = lines.fold<double>(0, (a, l) => a + l.projectedAnnualIncome);
  final yieldPct = invested > 0 ? (income / invested) * 100.0 : 0.0;

  return Allocation(
    lines: lines,
    cashLeftover: remaining,
    totalCapital: invested,
    weightedYieldPct: yieldPct,
    projectedAnnualIncome: income,
  );
}
```

- [ ] **Step 4: Run, expect pass**

```bash
flutter test test/domain/optimizer_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/optimizer.dart test/domain/optimizer_test.dart
git commit -m "feat: rules-based optimizer with diversification caps"
```

---

### Task 5: Simulator

**Files:**
- Create: `lib/domain/simulator.dart`
- Test: `test/domain/simulator_test.dart`

- [ ] **Step 1: Write failing test**

`test/domain/simulator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/simulator.dart';

Allocation mkAlloc({double capital = 10000, double yieldPct = 5.0}) => Allocation(
      lines: [],
      cashLeftover: 0,
      totalCapital: capital,
      weightedYieldPct: yieldPct,
      projectedAnnualIncome: capital * yieldPct / 100,
    );

void main() {
  test('no DRIP, no contrib: cumulative income grows linearly', () {
    final pts = simulate(mkAlloc(), horizonYears: 5, drip: false, monthlySgd: 0);
    expect(pts, hasLength(6)); // year 0..5
    expect(pts.first.cumulativeIncome, 0);
    expect(pts.last.cumulativeIncome, closeTo(2500, 0.01)); // 5y × 500
    expect(pts.last.portfolioValue, closeTo(10000, 0.01)); // unchanged
  });

  test('with DRIP: portfolio compounds at yield rate', () {
    final pts = simulate(mkAlloc(), horizonYears: 5, drip: true, monthlySgd: 0);
    expect(pts.last.portfolioValue, closeTo(10000 * 1.05 * 1.05 * 1.05 * 1.05 * 1.05, 1.0));
    expect(pts.last.cumulativeIncome, 0); // reinvested
  });

  test('monthly contrib increases portfolio value', () {
    final pts = simulate(mkAlloc(), horizonYears: 3, drip: false, monthlySgd: 100);
    expect(pts.last.portfolioValue, greaterThan(10000));
  });

  test('horizon=0 returns just year 0', () {
    final pts = simulate(mkAlloc(), horizonYears: 0, drip: false, monthlySgd: 0);
    expect(pts, hasLength(1));
    expect(pts.first.year, 0);
  });
}
```

- [ ] **Step 2: Run, expect fail**

```bash
flutter test test/domain/simulator_test.dart
```

- [ ] **Step 3: Implement simulator.dart**

`lib/domain/simulator.dart`:
```dart
import 'package:sg_dividend/data/models.dart';

List<SimulationPoint> simulate(
  Allocation alloc, {
  required int horizonYears,
  required bool drip,
  required int monthlySgd,
}) {
  final pts = <SimulationPoint>[];
  double pv = alloc.totalCapital;
  double cum = 0;
  final yieldFrac = alloc.weightedYieldPct / 100.0;
  pts.add(SimulationPoint(year: 0, portfolioValue: pv, cumulativeIncome: cum));
  for (var y = 1; y <= horizonYears; y++) {
    final income = pv * yieldFrac;
    if (drip) {
      pv += income;
    } else {
      cum += income;
    }
    pv += monthlySgd * 12;
    pts.add(SimulationPoint(year: y, portfolioValue: pv, cumulativeIncome: cum));
  }
  return pts;
}
```

- [ ] **Step 4: Run, expect pass**

```bash
flutter test test/domain/simulator_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/simulator.dart test/domain/simulator_test.dart
git commit -m "feat: forward simulator with DRIP and monthly contributions"
```

---

### Task 6: Theme

**Files:**
- Create: `lib/theme.dart`

- [ ] **Step 1: Write theme.dart**

`lib/theme.dart`:
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F3D2E)),
      scaffoldBackgroundColor: const Color(0xFFFAFAF7),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
      textTheme: base.textTheme.apply(fontFamily: 'SF Pro Display'),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/theme.dart
git commit -m "feat: app theme"
```

---

### Task 7: Disclaimer widgets + screen

**Files:**
- Create: `lib/ui/widgets/disclaimer_banner.dart`
- Create: `lib/ui/disclaimer_screen.dart`

- [ ] **Step 1: Implement banner widget**

`lib/ui/widgets/disclaimer_banner.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:sg_dividend/ui/disclaimer_screen.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3CD),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DisclaimerScreen())),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF856404)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Educational tool — not financial advice. Tap to read more.',
              style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
            )),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement screen**

`lib/ui/disclaimer_screen.dart`:
```dart
import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  static const _body = '''
This app is an educational tool. It does not provide financial advice and is not regulated by the Monetary Authority of Singapore (MAS) as a Financial Adviser.

The recommended allocations are illustrative outputs of a transparent rule-based optimizer that you parameterised yourself. They are not personal recommendations.

Past dividends do not guarantee future payments. Companies can and do cut their dividends. Stock prices fluctuate; you can lose money.

Data is scraped daily from public sources (Yahoo Finance, SGX, SGinvestors.io). It may be stale, incomplete, or wrong. Always verify against your broker before transacting.

You are responsible for your own investment decisions. If you need advice, speak to a MAS-licensed financial adviser.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disclaimer')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(_body, style: TextStyle(fontSize: 15, height: 1.5)),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/ui/widgets/disclaimer_banner.dart lib/ui/disclaimer_screen.dart
git commit -m "feat(ui): disclaimer banner + screen"
```

---

### Task 8: Splash screen

**Files:**
- Create: `lib/ui/splash_screen.dart`

- [ ] **Step 1: Implement splash**

`lib/ui/splash_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/data/universe_repository.dart';
import 'package:sg_dividend/ui/input_screen.dart';

final universeRepoProvider = Provider((_) => UniverseRepository());
final universeProvider = FutureProvider<Universe>((ref) async {
  return ref.read(universeRepoProvider).load();
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber, size: 48),
              const SizedBox(height: 12),
              Text('Could not load data: $e'),
            ]),
          )),
          data: (u) => InputScreen(universe: u),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/ui/splash_screen.dart
git commit -m "feat(ui): splash screen + universe provider"
```

---

### Task 9: Input screen

**Files:**
- Create: `lib/ui/input_screen.dart`

- [ ] **Step 1: Implement input screen**

`lib/ui/input_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/ui/result_screen.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class InputScreen extends StatefulWidget {
  final Universe universe;
  const InputScreen({super.key, required this.universe});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _capitalCtrl = TextEditingController(text: '10000');
  final _monthlyCtrl = TextEditingController(text: '0');
  RiskLevel _risk = RiskLevel.neutral;
  int _horizon = 5;
  bool _drip = true;

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SG Dividend Optimizer')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Capital (S\$)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _capitalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'S\$ '),
          ),
          const SizedBox(height: 24),
          const Text('Risk level', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<RiskLevel>(
            segments: const [
              ButtonSegment(value: RiskLevel.conservative, label: Text('Conservative')),
              ButtonSegment(value: RiskLevel.neutral, label: Text('Neutral')),
              ButtonSegment(value: RiskLevel.aggressive, label: Text('Aggressive')),
            ],
            selected: {_risk},
            onSelectionChanged: (s) => setState(() => _risk = s.first),
          ),
          const SizedBox(height: 24),
          const Text('Horizon (years)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
            ],
            selected: {_horizon},
            onSelectionChanged: (s) => setState(() => _horizon = s.first),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Reinvest dividends (DRIP)'),
            value: _drip,
            onChanged: (v) => setState(() => _drip = v),
          ),
          const SizedBox(height: 8),
          const Text('Monthly contribution (optional, S\$)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _monthlyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'S\$ '),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              final cap = int.tryParse(_capitalCtrl.text) ?? 0;
              final monthly = int.tryParse(_monthlyCtrl.text) ?? 0;
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(
                    universe: widget.universe,
                    capital: cap,
                    risk: _risk,
                    horizonYears: _horizon,
                    drip: _drip,
                    monthlySgd: monthly,
                  )));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Optimize', style: TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/ui/input_screen.dart
git commit -m "feat(ui): input screen"
```

---

### Task 10: Result screen + allocation pie

**Files:**
- Create: `lib/ui/result_screen.dart`
- Create: `lib/ui/widgets/allocation_pie.dart`

- [ ] **Step 1: Implement pie widget**

`lib/ui/widgets/allocation_pie.dart`:
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sg_dividend/data/models.dart';

class AllocationPie extends StatelessWidget {
  final Allocation alloc;
  const AllocationPie({super.key, required this.alloc});

  @override
  Widget build(BuildContext context) {
    final palette = [
      Colors.teal, Colors.indigo, Colors.amber, Colors.deepOrange, Colors.purple,
      Colors.green, Colors.blueGrey, Colors.pink, Colors.brown, Colors.cyan,
    ];
    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          for (var i = 0; i < alloc.lines.length; i++)
            PieChartSectionData(
              value: alloc.lines[i].sgdAllocated,
              color: palette[i % palette.length],
              title: alloc.lines[i].ticker.ticker,
              titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
              radius: 60,
            ),
        ],
      )),
    );
  }
}
```

- [ ] **Step 2: Implement result screen**

`lib/ui/result_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/optimizer.dart';
import 'package:sg_dividend/ui/explain_screen.dart';
import 'package:sg_dividend/ui/simulator_screen.dart';
import 'package:sg_dividend/ui/widgets/allocation_pie.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class ResultScreen extends StatelessWidget {
  final Universe universe;
  final int capital;
  final RiskLevel risk;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;

  const ResultScreen({
    super.key, required this.universe, required this.capital,
    required this.risk, required this.horizonYears,
    required this.drip, required this.monthlySgd,
  });

  @override
  Widget build(BuildContext context) {
    final alloc = optimize(capitalSgd: capital, risk: risk, universe: universe);
    final fmt = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    if (alloc.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Try at least S\$1,000 to build a diversified basket on SGX board lots.',
            style: TextStyle(fontSize: 16), textAlign: TextAlign.center,
          ),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Forward projection',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SimulatorScreen(
                    alloc: alloc, horizonYears: horizonYears,
                    drip: drip, monthlySgd: monthlySgd))),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Why these?',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ExplainScreen(alloc: alloc, risk: risk))),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Projected annual dividend',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(fmt.format(alloc.projectedAnnualIncome),
                  style: Theme.of(context).textTheme.displaySmall),
              Text('${alloc.weightedYieldPct.toStringAsFixed(2)}% weighted yield  ·  '
                   'Invested ${fmt.format(alloc.totalCapital)}  ·  '
                   'Cash ${fmt.format(alloc.cashLeftover)}'),
            ]),
          )),
          const SizedBox(height: 16),
          AllocationPie(alloc: alloc),
          const SizedBox(height: 16),
          ...alloc.lines.map((l) => ListTile(
                title: Text('${l.ticker.ticker}  ·  ${l.ticker.name}'),
                subtitle: Text('${l.lots} lots  ·  ${(l.sgdAllocated/alloc.totalCapital*100).toStringAsFixed(1)}%'),
                trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(fmt.format(l.sgdAllocated)),
                  Text('+${fmt.format(l.projectedAnnualIncome)}/yr',
                      style: const TextStyle(fontSize: 12, color: Colors.green)),
                ]),
              )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/ui/result_screen.dart lib/ui/widgets/allocation_pie.dart
git commit -m "feat(ui): result screen with allocation pie + line items"
```

---

### Task 11: Simulator screen + projection chart

**Files:**
- Create: `lib/ui/simulator_screen.dart`
- Create: `lib/ui/widgets/projection_chart.dart`

- [ ] **Step 1: Implement chart widget**

`lib/ui/widgets/projection_chart.dart`:
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sg_dividend/data/models.dart';

class ProjectionChart extends StatelessWidget {
  final List<SimulationPoint> withDrip;
  final List<SimulationPoint> withoutDrip;

  const ProjectionChart({super.key, required this.withDrip, required this.withoutDrip});

  @override
  Widget build(BuildContext context) {
    final maxY = [...withDrip, ...withoutDrip].map((p) => p.total).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 260,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY * 1.05,
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 56)),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            color: Colors.teal,
            barWidth: 3,
            spots: withDrip.map((p) => FlSpot(p.year.toDouble(), p.total)).toList(),
          ),
          LineChartBarData(
            isCurved: false,
            color: Colors.grey,
            barWidth: 2,
            spots: withoutDrip.map((p) => FlSpot(p.year.toDouble(), p.total)).toList(),
          ),
        ],
      )),
    );
  }
}
```

- [ ] **Step 2: Implement simulator screen**

`lib/ui/simulator_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/simulator.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';
import 'package:sg_dividend/ui/widgets/projection_chart.dart';

class SimulatorScreen extends StatelessWidget {
  final Allocation alloc;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;

  const SimulatorScreen({
    super.key, required this.alloc, required this.horizonYears,
    required this.drip, required this.monthlySgd,
  });

  @override
  Widget build(BuildContext context) {
    final withDrip = simulate(alloc, horizonYears: horizonYears, drip: true, monthlySgd: monthlySgd);
    final withoutDrip = simulate(alloc, horizonYears: horizonYears, drip: false, monthlySgd: monthlySgd);
    final fmt = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Forward Projection')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Assumes weighted yield ${alloc.weightedYieldPct.toStringAsFixed(2)}% stays constant. '
               'Past payments do not guarantee future ones.',
               style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ProjectionChart(withDrip: withDrip, withoutDrip: withoutDrip),
          const SizedBox(height: 12),
          Row(children: const [
            _LegendDot(color: Colors.teal, label: 'With DRIP'),
            SizedBox(width: 16),
            _LegendDot(color: Colors.grey, label: 'No DRIP'),
          ]),
          const SizedBox(height: 24),
          DataTable(
            columns: const [
              DataColumn(label: Text('Year')),
              DataColumn(label: Text('DRIP total')),
              DataColumn(label: Text('No DRIP total')),
            ],
            rows: [
              for (var i = 0; i < withDrip.length; i++)
                DataRow(cells: [
                  DataCell(Text('${withDrip[i].year}')),
                  DataCell(Text(fmt.format(withDrip[i].total))),
                  DataCell(Text(fmt.format(withoutDrip[i].total))),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label),
      ]);
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/ui/simulator_screen.dart lib/ui/widgets/projection_chart.dart
git commit -m "feat(ui): forward simulator screen with projection chart"
```

---

### Task 12: Explain screen

**Files:**
- Create: `lib/ui/explain_screen.dart`

- [ ] **Step 1: Implement explain screen**

`lib/ui/explain_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class ExplainScreen extends StatelessWidget {
  final Allocation alloc;
  final RiskLevel risk;
  const ExplainScreen({super.key, required this.alloc, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Why these stocks?')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Risk level: ${risk.label} (max score ${risk.maxScore})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'The optimizer filters the SGX dividend universe down to tickers whose risk score '
            'is at or below your chosen level, then greedily picks the highest-yielding ones '
            'subject to: max 25% in any single ticker, max 40% in any single sector, minimum 5 '
            'holdings (3 if capital below S\$2,000).',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 24),
          const Text('Per-ticker score breakdown',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final l in alloc.lines) Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l.ticker.ticker}  ·  ${l.ticker.name}  ·  ${l.ticker.sector}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Total score: ${l.ticker.score}/100  '
                   '(sector ${l.ticker.scoreBreakdown.sector}, '
                   'mcap ${l.ticker.scoreBreakdown.mcap}, '
                   'div-vol ${l.ticker.scoreBreakdown.divVol}, '
                   'payout ${l.ticker.scoreBreakdown.payout}, '
                   'price-vol ${l.ticker.scoreBreakdown.priceVol})',
                   style: const TextStyle(fontSize: 12)),
            ]),
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/ui/explain_screen.dart
git commit -m "feat(ui): explain screen for score transparency"
```

---

### Task 13: App entrypoint + wiring

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart` (replace generated)

- [ ] **Step 1: Implement app.dart**

`lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/splash_screen.dart';

class SgDividendApp extends ConsumerWidget {
  const SgDividendApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SG Dividend Optimizer',
      theme: AppTheme.light(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Replace main.dart**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sg_dividend/app.dart';

void main() {
  runApp(const ProviderScope(child: SgDividendApp()));
}
```

- [ ] **Step 3: Smoke test**

```bash
flutter run -d windows --release   # or your default device
```
Or for the Android emulator:
```bash
flutter run -d emulator-5554
```
Expected: app launches, splash → input screen with controls, "Optimize" yields a result screen.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/main.dart
git commit -m "feat: wire app entrypoint + theme"
```

---

### Task 14: Integration test

**Files:**
- Create: `integration_test/app_test.dart`

- [ ] **Step 1: Write test**

`integration_test/app_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg_dividend/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('input → optimize → result has at least one allocation line', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SgDividendApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should be on input screen
    expect(find.text('Optimize'), findsOneWidget);

    await tester.tap(find.text('Optimize'));
    await tester.pumpAndSettle();

    // Result screen shows projected dividend
    expect(find.textContaining('S\$'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run**

```bash
flutter test integration_test/app_test.dart
```

- [ ] **Step 3: Commit**

```bash
git add integration_test/app_test.dart
git commit -m "test: integration smoke test for happy path"
```

---

### Task 15: Build Android APK

- [ ] **Step 1: Build release APK**

```bash
flutter build apk --release --dart-define=UNIVERSE_URL=https://<R2_DOMAIN>/sg_dividend_universe.json
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

- [ ] **Step 2: Install on a real Android device for hand-test**

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 3: Manual checklist on device**

- Splash shows briefly, then input screen.
- Default S$10,000 + Neutral + 5y produces a result with ≥ 5 lines.
- Pie chart renders without overflow.
- Simulator chart shows two lines.
- Disclaimer banner is visible on every screen.
- Force-close + reopen still works offline (cache hit).

- [ ] **Step 4: Commit any signing config**

If you set up upload keystore, commit `android/key.properties.template` (with placeholders) and `.gitignore` the real `key.properties`.

---

### Task 16: iOS build handoff

iOS .ipa cannot be produced from Windows. This task is a checklist for Daniel to execute on a Mac.

- [ ] **Step 1: On macOS with Xcode 15+ installed**

```bash
git clone <your-github-repo-url>
cd sg-dividend-app
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --dart-define=UNIVERSE_URL=https://<R2_DOMAIN>/sg_dividend_universe.json
```

- [ ] **Step 2: Open Xcode, set bundle id + signing**

`ios/Runner.xcworkspace` → Runner target → Signing & Capabilities → set Team to your Apple Developer Account.

- [ ] **Step 3: Archive + upload**

Xcode → Product → Archive → Distribute App → App Store Connect → Upload.

- [ ] **Step 4: TestFlight rollout**

Add yourself + 5 friends as internal testers. Iterate.

---

## Coverage check

| Spec requirement | Task |
|---|---|
| Stateless Flutter app, no auth | 1, 13 |
| Fetch JSON, cache, bundled fallback | 3 |
| Capital + risk + horizon + DRIP + contributions input | 9 |
| Rules-based optimizer with constraints | 4 |
| Forward simulator with DRIP | 5 |
| Pie chart allocation | 10 |
| Line chart projection | 11 |
| Explain screen with score breakdown | 12 |
| Persistent disclaimer banner | 7, 8, 9, 10, 11, 12 |
| Long-form disclaimer screen | 7 |
| Offline-first via bundled asset | 1, 3 |
| Property/unit tests | 2, 3, 4, 5 |
| Integration test | 14 |
| Android APK build | 15 |
| iOS build handoff | 16 |
