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
}
