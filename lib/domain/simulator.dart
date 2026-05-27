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
