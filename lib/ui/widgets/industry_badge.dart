import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';

class IndustryBadge extends StatelessWidget {
  final String industry;
  final double fontSize;
  final EdgeInsets padding;
  const IndustryBadge({
    super.key,
    required this.industry,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  static Color colorFor(String industry) {
    switch (industry) {
      case 'Banks':
        return AppColors.chartBlue;
      case 'REITs':
        return AppColors.chartGreen;
      case 'Telco':
        return AppColors.chartViolet;
      case 'Utilities':
        return AppColors.chartTeal;
      case 'Industrials':
        return AppColors.chartAmber;
      case 'Consumer':
        return AppColors.chartOrange;
      case 'Business Trusts':
        return AppColors.chartIndigo;
      default:
        return AppColors.chartSlate;
    }
  }

  static String shortLabel(String industry) {
    switch (industry) {
      case 'Business Trusts':
        return 'TRUST';
      default:
        return industry.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFor(industry);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        shortLabel(industry),
        style: GoogleFonts.inter(
          color: c,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
