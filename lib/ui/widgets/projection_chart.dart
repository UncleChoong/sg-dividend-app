import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';

class ProjectionChart extends StatelessWidget {
  final List<SimulationPoint> withDrip;
  final List<SimulationPoint> withoutDrip;

  const ProjectionChart(
      {super.key, required this.withDrip, required this.withoutDrip});

  @override
  Widget build(BuildContext context) {
    final allPoints = [...withDrip, ...withoutDrip];
    if (allPoints.isEmpty) return const SizedBox(height: 260);

    final maxY =
        allPoints.map((p) => p.total).reduce((a, b) => a > b ? a : b);
    final fmt = NumberFormat.compactCurrency(
        locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    final labelStyle = GoogleFonts.inter(
        color: AppColors.textTertiary, fontSize: 10);

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.1,
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x0DFFFFFF), // 5% white
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Y${v.toInt()}', style: labelStyle),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (v, meta) => Text(
                  fmt.format(v),
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceElevated,
              tooltipBorder: const BorderSide(color: AppColors.border, width: 1),
              getTooltipItems: (spots) => spots.map((s) {
                final isDrip = s.barIndex == 0;
                return LineTooltipItem(
                  fmt.format(s.y),
                  GoogleFonts.inter(
                    color: isDrip ? AppColors.chartCyan : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            // With DRIP — bright cyan, 3px
            LineChartBarData(
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.chartCyan,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.chartCyan,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.chartCyan.withValues(alpha: 0.15),
                    AppColors.chartCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
              spots: withDrip
                  .map((p) => FlSpot(p.year.toDouble(), p.total))
                  .toList(),
            ),
            // No DRIP — muted gray, 1.5px
            LineChartBarData(
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.textTertiary,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [4, 4],
              spots: withoutDrip
                  .map((p) => FlSpot(p.year.toDouble(), p.total))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
