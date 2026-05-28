import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';

class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final List<Widget>? trailing;
  const BrandedAppBar({super.key, this.subtitle, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // APY wordmark with accent dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              'APY',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A0E1A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 10),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ],
      ),
      actions: [
        ...?trailing,
        const SizedBox(width: 4),
      ],
    );
  }
}
