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

  if (lines.length < minBasket) {
    // Universe lacks enough eligible diverse tickers. Caller surfaces a warning.
  }

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
