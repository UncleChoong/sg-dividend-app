import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/disclaimer_screen.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1508),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DisclaimerScreen())),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0x33FBBF24), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                size: 15, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Educational tool — not financial advice. Tap to read more.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFD4A017),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 15, color: Color(0xFFD4A017)),
          ]),
        ),
      ),
    );
  }
}
