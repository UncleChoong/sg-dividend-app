import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/data/universe_repository.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/landing_screen.dart';

final universeRepoProvider = Provider((_) => UniverseRepository());
final universeProvider = FutureProvider<Universe>((ref) async {
  return ref.read(universeRepoProvider).load();
});

/// Set by Home when an industry row is tapped; consumed by Stocks tab on next
/// activation to pre-apply the filter. Null means "no pending filter".
final pendingIndustryFilterProvider = StateProvider<String?>((_) => null);

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: _PendleLoader()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 32, color: AppColors.error),
                ),
                const SizedBox(height: 16),
                Text('Could not load data',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('$e',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),
          data: (u) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                );
              }
            });
            return const _PendleLoader();
          },
        ),
      ),
    );
  }
}

class _PendleLoader extends StatelessWidget {
  const _PendleLoader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 48,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'APY',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Loading universe…',
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
