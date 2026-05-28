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
              'Yields are smoothed using the last 3 years of actual dividend '
              'payments — not just the most recent year.',
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
              title: '3-year average dividend ÷ current price',
              body:
                  'We add up each company\'s total dividends in 2023, 2024 '
                  'and 2025, take the average, and divide by today\'s share '
                  'price. That gives a more representative figure than a '
                  'single year — special dividends and short-term spikes '
                  'don\'t inflate the number.',
            ),
            const SizedBox(height: 14),
            const _MethodologyRule(
              number: '2',
              title: 'Eligibility — must be currently paying',
              body:
                  'A company must have paid at least one dividend in 2025 or '
                  '2026 to appear here. Stocks that stopped paying years ago '
                  '(but still show a stale yield on Yahoo) are excluded.',
            ),
            const SizedBox(height: 14),
            const _MethodologyRule(
              number: '3',
              title: 'Newer listings use available history',
              body:
                  'A company that only has 1-2 years of payment history is '
                  'averaged over the years it has — we don\'t pretend to know '
                  'what it would have paid before it started.',
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
                    Text('Example: Aztech Global (8AZ)',
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        )),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    'Aztech paid S\$0.045 in 2023, S\$0.10 in 2024 and S\$0.11 '
                    'in 2025. Their 3-year average is S\$0.085. On a S\$0.945 '
                    'share price, that\'s a 9% yield.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A naive last-year-only number would show 11.6% — '
                    'misleading because it ignores that Aztech is paying out '
                    '~77% of earnings, which can\'t grow much further.',
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
              'Past dividends are not a guarantee of future payments. The '
              'simulator\'s projections assume the 3-year average continues '
              '— a company can always cut, suspend or grow its dividend.',
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
