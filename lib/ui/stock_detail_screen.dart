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

    // Build bar chart data from div history (index 0 = most recent)
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

    // Score component bars: (label, value, max)
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
        title: Text('${t.ticker} · ${t.name}',
            overflow: TextOverflow.ellipsis),
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  'S\$${t.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${t.yieldPct.toStringAsFixed(2)}% yield',
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(t.sector,
                    style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Company description
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
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5)),
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

          // Dividend history bar chart
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
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          // index 0 = most recent year; reverse for display
                          final yearOffset =
                              t.divHistory5y.length - 1 - value.toInt();
                          final year = currentYear - yearOffset;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('$year',
                                style: GoogleFonts.inter(
                                    color: AppColors.textTertiary,
                                    fontSize: 10)),
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
              children: scoreComponents.map((entry) {
                final (label, value, max) = entry;
                final fraction = max > 0 ? value / max : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                          child: Text(label,
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13))),
                      Text('$value / $max',
                          style: GoogleFonts.inter(
                              color: AppColors.textTertiary, fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fraction > 0.7
                              ? AppColors.error
                              : fraction > 0.4
                                  ? AppColors.chartAmber
                                  : AppColors.secondary,
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
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0));
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
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ]);
  }
}
