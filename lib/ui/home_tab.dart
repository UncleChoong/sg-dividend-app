import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/main_shell.dart';
import 'package:sg_dividend/ui/splash_screen.dart';
import 'package:sg_dividend/ui/stock_detail_screen.dart';
import 'package:sg_dividend/ui/widgets/branded_app_bar.dart';
import 'package:sg_dividend/ui/widgets/industry_badge.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BrandedAppBar(subtitle: 'Dashboard'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) => _HomeContent(universe: u, ref: ref),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Universe universe;
  final WidgetRef ref;
  const _HomeContent({required this.universe, required this.ref});

  @override
  Widget build(BuildContext context) {
    final tickers = universe.tickers;
    final avgYield = tickers.isEmpty
        ? 0.0
        : tickers.fold<double>(0, (s, t) => s + t.yieldPct) / tickers.length;
    final topYielders = [...tickers]
      ..sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
    final featured = topYielders.take(5).toList();

    // Industry breakdown — counts and ordered list
    final industryCounts = <String, int>{};
    for (final t in tickers) {
      final key = t.industry.isEmpty ? t.sector : t.industry;
      industryCounts[key] = (industryCounts[key] ?? 0) + 1;
    }
    final industries = industryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Score distribution
    final conservative = tickers.where((t) => t.score <= 35).length;
    final neutral = tickers.where((t) => t.score > 35 && t.score <= 60).length;
    final aggressive = tickers.where((t) => t.score > 60).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Gradient hero card ────────────────────────────────────────
        _GradientHero(
          tickerCount: tickers.length,
          avgYield: avgYield,
          topYield: featured.isEmpty ? 0.0 : featured.first.yieldPct,
        ),
        const SizedBox(height: 20),

        // ── Industry breakdown (donut + rows, iFast Summary card) ─────
        _IndustryBreakdownCard(
          industries: industries,
          total: tickers.length,
          onIndustryTap: (industry) {
            ref.read(pendingIndustryFilterProvider.notifier).state = industry;
            final shell = context.findAncestorStateOfType<MainShellState>();
            shell?.switchToTab(1);
          },
        ),
        const SizedBox(height: 16),

        // ── Featured / Top yielders horizontal scroller ───────────────
        _SectionHeader(
          title: 'Top Yielders',
          actionLabel: 'See all',
          onAction: () {
            final shell = context.findAncestorStateOfType<MainShellState>();
            shell?.switchToTab(1);
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _FeaturedCard(ticker: featured[i]),
          ),
        ),
        const SizedBox(height: 20),

        // ── Risk score distribution ───────────────────────────────────
        _Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Label('RISK SCORE DISTRIBUTION'),
            const SizedBox(height: 16),
            _ScoreBar(
                label: 'Conservative (≤35)',
                count: conservative,
                total: tickers.length,
                color: AppColors.secondary),
            const SizedBox(height: 10),
            _ScoreBar(
                label: 'Neutral (36–60)',
                count: neutral,
                total: tickers.length,
                color: AppColors.chartAmber),
            const SizedBox(height: 10),
            _ScoreBar(
                label: 'Aggressive (61–100)',
                count: aggressive,
                total: tickers.length,
                color: AppColors.error),
          ]),
        ),
        const SizedBox(height: 24),

        // ── Quick Optimize CTA ───────────────────────────────────────
        _OptimizeCta(),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/disclaimer'),
            child: Text('Disclaimer',
                style: GoogleFonts.inter(
                    color: AppColors.textTertiary, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Gradient hero (iFast YTD/Total card)
// ═════════════════════════════════════════════════════════════════════
class _GradientHero extends StatelessWidget {
  final int tickerCount;
  final double avgYield;
  final double topYield;
  const _GradientHero({
    required this.tickerCount,
    required this.avgYield,
    required this.topYield,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2A2A), Color(0xFF0A1428)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.show_chart_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text('Singapore Dividend Universe',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                )),
          ]),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avg Yield',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 4),
                    Text('${avgYield.toStringAsFixed(2)}%',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ],
                        )),
                    const SizedBox(height: 2),
                    Text('p.a. across $tickerCount stocks',
                        style: GoogleFonts.inter(
                            color: AppColors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.border,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Yield',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 4),
                    Text('${topYield.toStringAsFixed(2)}%',
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.0,
                        )),
                    const SizedBox(height: 2),
                    Text('best in universe',
                        style: GoogleFonts.inter(
                            color: AppColors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Industry breakdown (donut + iFast-style breakdown rows)
// ═════════════════════════════════════════════════════════════════════
class _IndustryBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, int>> industries;
  final int total;
  final ValueChanged<String> onIndustryTap;
  const _IndustryBreakdownCard({
    required this.industries,
    required this.total,
    required this.onIndustryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (industries.isEmpty || total == 0) return const SizedBox.shrink();
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('SECTOR BREAKDOWN'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 56,
                sections: [
                  for (final e in industries)
                    PieChartSectionData(
                      value: e.value.toDouble(),
                      color: IndustryBadge.colorFor(e.key),
                      title: '',
                      radius: 24,
                    ),
                ],
              )),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                  const SizedBox(height: 2),
                  Text('Stocks',
                      style: GoogleFonts.inter(
                          color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // iFast-style breakdown rows: vertical color bar + label + % + count
        // Tappable — links to Stocks tab filtered by the industry.
        ...industries.map((e) {
          final pct = total == 0 ? 0.0 : (e.value / total) * 100;
          return InkWell(
            onTap: () => onIndustryTap(e.key),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(children: [
                Container(
                  width: 4,
                  height: 26,
                  decoration: BoxDecoration(
                    color: IndustryBadge.colorFor(e.key),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.key,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
                Text('${pct.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text('${e.value}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                          color: AppColors.textTertiary, fontSize: 12)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary.withValues(alpha: 0.7),
                    size: 18),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Featured stock card (horizontal scroller item)
// ═════════════════════════════════════════════════════════════════════
class _FeaturedCard extends StatelessWidget {
  final Ticker ticker;
  const _FeaturedCard({required this.ticker});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StockDetailScreen(ticker: ticker)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IndustryBadge(industry: ticker.industry),
            const Spacer(),
            Text(ticker.ticker,
                style: GoogleFonts.robotoMono(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ]),
          const SizedBox(height: 10),
          Text(ticker.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
              )),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${ticker.yieldPct.toStringAsFixed(2)}%',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1,
                )),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('yield',
                  style: GoogleFonts.inter(
                      color: AppColors.textTertiary, fontSize: 10)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Section header + Optimize CTA + supporting bits
// ═════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          )),
      const Spacer(),
      if (actionLabel != null)
        InkWell(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(children: [
              Text(actionLabel!,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.primary, size: 14),
            ]),
          ),
        ),
    ]);
  }
}

class _OptimizeCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: () {
          final shell = context.findAncestorStateOfType<MainShellState>();
          shell?.switchToTab(2);
        },
        icon: const Icon(Icons.tune_rounded, size: 20),
        label: const Text('Optimize Portfolio'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
        ),
      ),
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
