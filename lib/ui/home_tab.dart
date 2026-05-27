import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/main_shell.dart';
import 'package:sg_dividend/ui/splash_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('APY')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) => _HomeContent(universe: u),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Universe universe;
  const _HomeContent({required this.universe});

  @override
  Widget build(BuildContext context) {
    final tickers = universe.tickers;
    final avgYield = tickers.isEmpty
        ? 0.0
        : tickers.fold<double>(0, (s, t) => s + t.yieldPct) / tickers.length;
    final topYielder = tickers.isEmpty
        ? null
        : tickers.reduce((a, b) => a.yieldPct > b.yieldPct ? a : b);

    // Sector breakdown
    final sectorCounts = <String, int>{};
    for (final t in tickers) {
      sectorCounts[t.sector] = (sectorCounts[t.sector] ?? 0) + 1;
    }

    // Score distribution
    final conservative = tickers.where((t) => t.score <= 35).length;
    final neutral = tickers.where((t) => t.score > 35 && t.score <= 60).length;
    final aggressive = tickers.where((t) => t.score > 60).length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Hero card
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Label('UNIVERSE'),
            const SizedBox(height: 12),
            Text(
              '${tickers.length} SGX dividend stocks tracked',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Average yield: ${avgYield.toStringAsFixed(2)}% p.a.',
              style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Top yielder
        if (topYielder != null) ...[
          _Card(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('TOP YIELDER'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topYielder.ticker,
                                style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(topYielder.name,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(topYielder.sector,
                                style: GoogleFonts.inter(
                                    color: AppColors.textTertiary,
                                    fontSize: 12)),
                          ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${topYielder.yieldPct.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)),
                      Text('yield p.a.',
                          style: GoogleFonts.inter(
                              color: AppColors.textTertiary, fontSize: 11)),
                    ]),
                  ]),
                ]),
          ),
          const SizedBox(height: 16),
        ],

        // Sector breakdown
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Label('SECTOR BREAKDOWN'),
            const SizedBox(height: 16),
            ...sectorCounts.entries.map((e) {
              final fraction = e.value / tickers.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(e.key,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13))),
                        Text('${e.value}',
                            style: GoogleFonts.inter(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ]),
              );
            }),
          ]),
        ),
        const SizedBox(height: 16),

        // Score distribution
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Label('RISK SCORE DISTRIBUTION'),
            const SizedBox(height: 16),
            _ScoreBar(
                label: 'Conservative (≤35)',
                count: conservative,
                total: tickers.length,
                color: AppColors.secondary),
            const SizedBox(height: 8),
            _ScoreBar(
                label: 'Neutral (36–60)',
                count: neutral,
                total: tickers.length,
                color: AppColors.chartAmber),
            const SizedBox(height: 8),
            _ScoreBar(
                label: 'Aggressive (61–100)',
                count: aggressive,
                total: tickers.length,
                color: AppColors.error),
          ]),
        ),
        const SizedBox(height: 24),

        // Quick Optimize CTA
        FilledButton.icon(
          onPressed: () {
            final shell = context.findAncestorStateOfType<MainShellState>();
            shell?.switchToTab(2);
          },
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Quick Optimize'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/disclaimer'),
            child: Text('Disclaimer',
                style: GoogleFonts.inter(
                    color: AppColors.textTertiary, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _ScoreBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12))),
        Text('$count',
            style:
                GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 6,
          backgroundColor: AppColors.surfaceElevated,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0));
  }
}
