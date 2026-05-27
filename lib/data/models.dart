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
  final String industry;
  final String description;
  final double? marketCapSgd;
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
      ? (divHistory5y
                  .take(3)
                  .whereType<double>()
                  .fold<double>(0, (a, b) => a + b) /
              price *
              100)
      : 0;
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
