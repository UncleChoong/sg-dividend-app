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
