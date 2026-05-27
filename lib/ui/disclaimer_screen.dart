import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  static const _sections = [
    (
      'Educational Tool',
      'This app is an educational tool. It does not provide financial advice and is not regulated by the Monetary Authority of Singapore (MAS) as a Financial Adviser.',
    ),
    (
      'Not a Personal Recommendation',
      'The recommended allocations are illustrative outputs of a transparent rule-based optimizer that you parameterised yourself. They are not personal recommendations.',
    ),
    (
      'No Dividend Guarantee',
      'Past dividends do not guarantee future payments. Companies can and do cut their dividends. Stock prices fluctuate; you can lose money.',
    ),
    (
      'Data Accuracy',
      'Data is scraped daily from public sources (Yahoo Finance, SGX, SGinvestors.io). It may be stale, incomplete, or wrong. Always verify against your broker before transacting.',
    ),
    (
      'Your Responsibility',
      'You are responsible for your own investment decisions. If you need advice, speak to a MAS-licensed financial adviser.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disclaimer')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Top warning banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This is not financial advice. Read carefully before making investment decisions.',
                  style: GoogleFonts.inter(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          for (final section in _sections) ...[
            _DisclaimerSection(title: section.$1, body: section.$2),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DisclaimerSection extends StatelessWidget {
  final String title;
  final String body;
  const _DisclaimerSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 13, height: 1.55),
          ),
        ],
      ),
    );
  }
}
