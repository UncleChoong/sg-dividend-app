import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/main_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _enter(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Wordmark
              Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF60A5FA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      'APY',
                      style: GoogleFonts.inter(
                        fontSize: 88,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -4,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Cyan glow underline
                  Container(
                    height: 3,
                    width: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Singapore Dividend Yield Simulator',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const Spacer(flex: 4),
              // Enter button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () => _enter(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(200, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: const Text('Enter'),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
