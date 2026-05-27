import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/simulator.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';
import 'package:sg_dividend/ui/widgets/projection_chart.dart';

class SimulatorScreen extends StatelessWidget {
  final Allocation alloc;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;

  const SimulatorScreen({
    super.key,
    required this.alloc,
    required this.horizonYears,
    required this.drip,
    required this.monthlySgd,
  });

  @override
  Widget build(BuildContext context) {
    final withDrip = simulate(alloc,
        horizonYears: horizonYears, drip: true, monthlySgd: monthlySgd);
    final withoutDrip = simulate(alloc,
        horizonYears: horizonYears, drip: false, monthlySgd: monthlySgd);
    final fmt =
        NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Forward Projection')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Disclaimer text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              'Assumes weighted yield ${alloc.weightedYieldPct.toStringAsFixed(2)}% stays constant. '
              'Past payments do not guarantee future ones.',
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          // Chart card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PORTFOLIO VALUE OVER TIME',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                ProjectionChart(
                    withDrip: withDrip, withoutDrip: withoutDrip),
                const SizedBox(height: 16),
                // Legend
                const Row(children: [
                  _LegendItem(color: AppColors.chartCyan, label: 'With DRIP'),
                  SizedBox(width: 20),
                  _LegendItem(
                      color: AppColors.textTertiary, label: 'No DRIP'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Data table
          Text(
            'YEAR-BY-YEAR BREAKDOWN',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  color: AppColors.surfaceElevated,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(
                        flex: 1,
                        child: Text('Year',
                            style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5))),
                    Expanded(
                        flex: 2,
                        child: Text('DRIP total',
                            style: GoogleFonts.inter(
                                color: AppColors.chartCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5))),
                    Expanded(
                        flex: 2,
                        child: Text('No DRIP total',
                            style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5))),
                  ]),
                ),
                for (var i = 0; i < withDrip.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border,
                        indent: 16,
                        endIndent: 16),
                  Container(
                    color: i.isOdd
                        ? AppColors.surfaceElevated.withValues(alpha: 0.5)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Expanded(
                          flex: 1,
                          child: Text(
                            '${withDrip[i].year}',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          )),
                      Expanded(
                          flex: 2,
                          child: Text(
                            fmt.format(withDrip[i].total),
                            style: GoogleFonts.inter(
                                color: AppColors.chartCyan,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          )),
                      Expanded(
                          flex: 2,
                          child: Text(
                            fmt.format(withoutDrip[i].total),
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13),
                          )),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          ), // ClipRRect
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 24,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: GoogleFonts.inter(
            color: color == AppColors.chartCyan
                ? AppColors.chartCyan
                : AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500),
      ),
    ]);
  }
}
