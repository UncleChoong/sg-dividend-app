import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/widgets/industry_badge.dart';
import 'package:sg_dividend/ui/widgets/yield_methodology_dialog.dart';

class StockDetailScreen extends StatelessWidget {
  final Ticker ticker;
  const StockDetailScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    final t = ticker;
    final fmt = NumberFormat.compactCurrency(locale: 'en_SG', symbol: 'S\$');
    final currentYear = DateTime.now().year;
    final industry = t.industry.isEmpty ? t.sector : t.industry;
    final industryColor = IndustryBadge.colorFor(industry);

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < t.divHistory5y.length; i++) {
      final val = t.divHistory5y[i];
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val ?? 0,
            color: val == null ? AppColors.textTertiary : AppColors.primary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    final scoreComponents = [
      ('Sector', t.scoreBreakdown.sector, 30),
      ('Market Cap', t.scoreBreakdown.mcap, 10),
      ('Dividend Volatility', t.scoreBreakdown.divVol, 20),
      ('Payout', t.scoreBreakdown.payout, 20),
      ('Price Volatility', t.scoreBreakdown.priceVol, 20),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.ticker,
            style: GoogleFonts.robotoMono(
                fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Gradient hero ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  industryColor.withValues(alpha: 0.18),
                  const Color(0xFF0A1428),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: industryColor.withValues(alpha: 0.35), width: 1),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IndustryBadge(industry: industry, fontSize: 11),
                    const Spacer(),
                    Text(t.ticker,
                        style: GoogleFonts.robotoMono(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        )),
                  ]),
                  const SizedBox(height: 12),
                  Text(t.name,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.15,
                      )),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PRICE',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textTertiary,
                                      fontSize: 10,
                                      letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text('S\$${t.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    height: 1,
                                  )),
                            ]),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text('YIELD (3-YR AVG)',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textTertiary,
                                        fontSize: 10,
                                        letterSpacing: 0.8)),
                                const SizedBox(width: 2),
                                const YieldInfoButton(),
                              ]),
                              const SizedBox(height: 4),
                              Text('${t.yieldPct.toStringAsFixed(2)}%',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    height: 1,
                                    shadows: [
                                      Shadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.4),
                                          blurRadius: 14),
                                    ],
                                  )),
                            ]),
                      ),
                    ],
                  ),
                ]),
          ),
          const SizedBox(height: 20),

          // ── Stat strip (3y yield · risk · lot) ─────────────────────
          Row(children: [
            Expanded(
              child: _StatTile(
                label: '3Y YIELD',
                value:
                    '${t.threeYearCumulativeYieldPct.toStringAsFixed(1)}%',
                accent: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'RISK',
                value: '${t.score}',
                accent: t.score <= 35
                    ? AppColors.secondary
                    : t.score <= 60
                        ? AppColors.chartAmber
                        : AppColors.error,
                suffix: '/100',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                label: 'LOT',
                value: '${t.lotSize}',
                accent: AppColors.textPrimary,
                suffix: 'shares',
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Company description ────────────────────────────────────
          if (t.description.isNotEmpty) ...[
            const _SectionLabel('COMPANY'),
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
                      height: 1.55)),
            ),
            const SizedBox(height: 20),
          ],

          // ── Market data ────────────────────────────────────────────
          const _SectionLabel('MARKET DATA'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              if (t.marketCapSgd != null) ...[
                _DataRow('Market Cap', fmt.format(t.marketCapSgd)),
                const Divider(height: 1, color: AppColors.border),
              ],
              _DataRow('Sector', t.sector),
              const Divider(height: 1, color: AppColors.border),
              _DataRow('Industry', industry),
              const Divider(height: 1, color: AppColors.border),
              _DataRow('Lot Size', '${t.lotSize} shares'),
              const Divider(height: 1, color: AppColors.border),
              _DataRow('Min. Investment',
                  'S\$${(t.price * t.lotSize).toStringAsFixed(2)}'),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Dividend history bar chart ─────────────────────────────
          const _SectionLabel('5-YEAR DIVIDEND HISTORY (S\$ per share)'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SizedBox(
              height: 170,
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(value.toStringAsFixed(2),
                                style: GoogleFonts.inter(
                                    color: AppColors.textTertiary,
                                    fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
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

          // ── Risk score breakdown ───────────────────────────────────
          const _SectionLabel('RISK SCORE BREAKDOWN'),
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
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(label,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 13))),
                          Text('$value / $max',
                              style: GoogleFonts.inter(
                                  color: AppColors.textTertiary,
                                  fontSize: 12)),
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color accent;
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value,
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1,
                )),
            if (suffix != null) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(suffix!,
                    style: GoogleFonts.inter(
                        color: AppColors.textTertiary, fontSize: 10)),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
