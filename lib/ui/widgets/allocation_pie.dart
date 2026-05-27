import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';

class AllocationPie extends StatelessWidget {
  final Allocation alloc;
  const AllocationPie({super.key, required this.alloc});

  @override
  Widget build(BuildContext context) {
    // Pendle-style dark palette: cyan + greens + blues, no garish purples
    const palette = [
      AppColors.chartCyan,
      AppColors.chartGreen,
      AppColors.chartBlue,
      AppColors.chartAmber,
      AppColors.chartViolet,
      AppColors.chartOrange,
      AppColors.chartTeal,
      AppColors.chartIndigo,
      AppColors.chartPink,
      AppColors.chartSlate,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 48,
            sections: [
              for (var i = 0; i < alloc.lines.length; i++)
                PieChartSectionData(
                  value: alloc.lines[i].sgdAllocated.toDouble(),
                  color: palette[i % palette.length],
                  title: alloc.lines[i].ticker.ticker,
                  titleStyle: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  radius: 64,
                ),
            ],
          )),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < alloc.lines.length; i++)
              _PieLegendItem(
                color: palette[i % palette.length],
                ticker: alloc.lines[i].ticker.ticker,
              ),
          ],
        ),
      ],
    );
  }
}

class _PieLegendItem extends StatelessWidget {
  final Color color;
  final String ticker;
  const _PieLegendItem({required this.color, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        ticker,
        style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500),
      ),
    ]);
  }
}
