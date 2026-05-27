import 'package:flutter_test/flutter_test.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/optimizer.dart';

Ticker mk(String t, {
  String sector = 'Banks',
  String? industry,
  double price = 10.0,
  double yieldPct = 5.0,
  int score = 20,
  int lotSize = 100,
}) => Ticker(
      ticker: t, name: t, sector: sector,
      industry: industry ?? sector,
      price: price, yieldPct: yieldPct,
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

    test('residual pass does not blow through diversification caps', () {
      // Universe with only 2 sectors; the greedy pass leaves a chunk of residual.
      final u = Universe(
        generatedAt: DateTime.now(), schemaVersion: 1,
        tickers: [
          mk('B1', sector: 'Banks', score: 10, yieldPct: 6.0),
          mk('B2', sector: 'Banks', score: 12, yieldPct: 5.5),
          mk('U1', sector: 'Utilities', score: 15, yieldPct: 4.0),
        ],
      );
      final r = optimize(capitalSgd: 10000, risk: RiskLevel.aggressive, universe: u);
      for (final l in r.lines) {
        expect(l.sgdAllocated, lessThanOrEqualTo(2500.01),
            reason: '${l.ticker.ticker} > 25% after residual pass');
      }
      final perSector = <String, double>{};
      for (final l in r.lines) {
        perSector[l.ticker.sector] =
            (perSector[l.ticker.sector] ?? 0) + l.sgdAllocated;
      }
      for (final v in perSector.values) {
        expect(v, lessThanOrEqualTo(4000.01));
      }
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
  });
}
