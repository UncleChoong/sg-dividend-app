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
    expect(pts, hasLength(6));
    expect(pts.first.cumulativeIncome, 0);
    expect(pts.last.cumulativeIncome, closeTo(2500, 0.01));
    expect(pts.last.portfolioValue, closeTo(10000, 0.01));
  });

  test('with DRIP: portfolio compounds at yield rate', () {
    final pts = simulate(mkAlloc(), horizonYears: 5, drip: true, monthlySgd: 0);
    expect(pts.last.portfolioValue, closeTo(10000 * 1.05 * 1.05 * 1.05 * 1.05 * 1.05, 1.0));
    expect(pts.last.cumulativeIncome, 0);
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
