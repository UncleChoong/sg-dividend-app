import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/optimizer.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/explain_screen.dart';
import 'package:sg_dividend/ui/simulator_screen.dart';
import 'package:sg_dividend/ui/widgets/allocation_pie.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class ResultScreen extends StatelessWidget {
  final Universe universe;
  final int capital;
  final RiskLevel risk;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;
  final Set<String>? includedIndustries;

  const ResultScreen({
    super.key,
    required this.universe,
    required this.capital,
    required this.risk,
    required this.horizonYears,
    required this.drip,
    required this.monthlySgd,
    this.includedIndustries,
  });

  @override
  Widget build(BuildContext context) {
    final alloc = optimize(
        capitalSgd: capital,
        risk: risk,
        universe: universe,
        includedIndustries: includedIndustries);
    final fmt = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    if (alloc.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 36, color: AppColors.warning),
              ),
              const SizedBox(height: 20),
              Text(
                'Insufficient Capital',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Try at least S\$1,000 to build a diversified basket on SGX board lots.',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: 'Forward projection',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SimulatorScreen(
                      alloc: alloc,
                      horizonYears: horizonYears,
                      drip: drip,
                      monthlySgd: monthlySgd,
                    ))),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Why these?',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ExplainScreen(alloc: alloc, risk: risk))),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Hero card
          _HeroCard(alloc: alloc, fmt: fmt),
          const SizedBox(height: 24),
          // Pie chart
          const _SectionLabel(label: 'ALLOCATION BREAKDOWN'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: AllocationPie(alloc: alloc),
          ),
          const SizedBox(height: 24),
          // Holdings table
          const _SectionLabel(label: 'HOLDINGS'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                for (var i = 0; i < alloc.lines.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1,
                        color: AppColors.border, indent: 16, endIndent: 16),
                  _AllocationRow(
                    line: alloc.lines[i],
                    total: alloc.totalCapital,
                    fmt: fmt,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Allocation alloc;
  final NumberFormat fmt;
  const _HeroCard({required this.alloc, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'PROJECTED ANNUAL DIVIDEND',
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        // Hero number with glow
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            fmt.format(alloc.projectedAnnualIncome),
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Yield badge
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              '${alloc.weightedYieldPct.toStringAsFixed(2)}% weighted yield',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        const SizedBox(height: 12),
        Row(children: [
          _MetaStat(
              label: 'Invested', value: fmt.format(alloc.totalCapital)),
          const SizedBox(width: 24),
          _MetaStat(
              label: 'Cash left',
              value: fmt.format(alloc.cashLeftover)),
          const SizedBox(width: 24),
          _MetaStat(
              label: 'Holdings',
              value: '${alloc.lines.length} stocks'),
        ]),
      ]),
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String label;
  final String value;
  const _MetaStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.inter(
              color: AppColors.textTertiary, fontSize: 11, letterSpacing: 0.3)),
      const SizedBox(height: 2),
      Text(value,
          style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    ]);
  }
}

class _AllocationRow extends StatelessWidget {
  final AllocationLine line;
  final double total;
  final NumberFormat fmt;
  const _AllocationRow(
      {required this.line, required this.total, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0
        ? (line.sgdAllocated / total * 100).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              line.ticker.ticker,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              line.ticker.name,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$pct% · ${line.lots} lots',
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary, fontSize: 11),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            fmt.format(line.sgdAllocated),
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '+${fmt.format(line.projectedAnnualIncome)}/yr',
            style: GoogleFonts.inter(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ]),
      ]),
    );
  }
}
