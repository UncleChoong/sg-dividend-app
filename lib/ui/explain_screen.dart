import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class ExplainScreen extends StatelessWidget {
  final Allocation alloc;
  final RiskLevel risk;
  const ExplainScreen({super.key, required this.alloc, required this.risk});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Why these stocks?')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Risk level banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Risk level: ${risk.label}  ·  Max score ${risk.maxScore}',
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          // Explanation text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              'The optimizer filters the SGX dividend universe down to tickers whose risk score '
              'is at or below your chosen level, then greedily picks the highest-yielding ones '
              'subject to: max 25% in any single ticker, max 40% in any single sector, minimum 5 '
              'holdings (3 if capital below S\$2,000).',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PER-TICKER SCORE BREAKDOWN',
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          for (final l in alloc.lines) ...[
            _TickerCard(line: l),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TickerCard extends StatelessWidget {
  final AllocationLine line;
  const _TickerCard({required this.line});

  Color _scoreColor(int score) {
    if (score <= 30) return AppColors.primary;
    if (score <= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(line.ticker.score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.ticker.ticker,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line.ticker.name,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line.ticker.sector,
                    style: GoogleFonts.inter(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scoreColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Text(
                '${line.ticker.score}/100',
                style: GoogleFonts.inter(
                    color: scoreColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),
          // Score breakdown
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ScoreChip(
                  label: 'Sector',
                  value: line.ticker.scoreBreakdown.sector),
              _ScoreChip(
                  label: 'MCap',
                  value: line.ticker.scoreBreakdown.mcap),
              _ScoreChip(
                  label: 'Div-Vol',
                  value: line.ticker.scoreBreakdown.divVol),
              _ScoreChip(
                  label: 'Payout',
                  value: line.ticker.scoreBreakdown.payout),
              _ScoreChip(
                  label: 'Price-Vol',
                  value: line.ticker.scoreBreakdown.priceVol),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int value;
  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 11),
          children: [
            TextSpan(
                text: label,
                style: const TextStyle(color: AppColors.textTertiary)),
            const TextSpan(
                text: ' ',
                style: TextStyle(color: AppColors.textTertiary)),
            TextSpan(
                text: '$value',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
