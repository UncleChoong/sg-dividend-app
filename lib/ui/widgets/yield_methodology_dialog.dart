import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';

/// Bottom sheet explaining how the displayed yield % is computed.
///
/// The user explicitly asked for this disclosure ("we need to explain to people
/// that the yield is annualized…") because the numbers can differ from what
/// users see on Yahoo Finance / Bloomberg, which use TTM yields.
class YieldMethodologyDialog {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _YieldMethodologyContent(),
    );
  }
}

class _YieldMethodologyContent extends StatelessWidget {
  const _YieldMethodologyContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('How yield is calculated',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
            ]),
            const SizedBox(height: 18),

            // Headline
            Text(
              'All yields shown are annualized full-year run-rate estimates.',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            // Methodology block
            const _MethodologyRule(
              number: '1',
              title: 'For stocks already paying in 2026',
              body:
                  'We take the dividends paid year-to-date and scale them up '
                  'using the prior year\'s payment pattern. A quarterly payer '
                  'that has paid Q1 gets multiplied by roughly 4×; a '
                  'semi-annual payer ~2×; an annual payer 1×.',
            ),
            const SizedBox(height: 14),
            const _MethodologyRule(
              number: '2',
              title: 'For stocks not yet paying in 2026',
              body:
                  'We use the full 2025 dividend payout as a benchmark — what '
                  'the company most recently paid for a complete year.',
            ),
            const SizedBox(height: 14),
            const _MethodologyRule(
              number: '3',
              title: 'Special dividends are filtered out',
              body:
                  'If the annualized estimate would be more than 1.5× the prior '
                  'year\'s payout, we assume the partial-year amount includes a '
                  'one-off special dividend and fall back to the 2025 total.',
            ),
            const SizedBox(height: 20),

            // Worked example
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text('Example: DBS Group (D05)',
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        )),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    'DBS pays quarterly. By May 2026 they\'ve paid their Q1 '
                    'dividend of about S\$0.54. We scale it to a full year (×4) '
                    'using their 2025 quarterly cadence, giving roughly S\$2.16 '
                    'expected annual income per share.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'On a S\$62 share price, that\'s a 3.5% yield — what DBS is '
                    'actually paying right now, not last year\'s number.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Caveat
            Text(
              'Stocks that have not paid a dividend in either 2025 or 2026 '
              'are excluded from the universe entirely.',
              style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Dismiss
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodologyRule extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _MethodologyRule({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(number,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              )),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              Text(body,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}


/// Compact info-icon button that opens the methodology dialog.
class YieldInfoButton extends StatelessWidget {
  final double size;
  final Color? color;
  const YieldInfoButton({super.key, this.size = 14, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => YieldMethodologyDialog.show(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.info_outline_rounded,
          size: size,
          color: color ?? AppColors.textTertiary,
        ),
      ),
    );
  }
}
