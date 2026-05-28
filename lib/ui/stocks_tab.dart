import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/splash_screen.dart';
import 'package:sg_dividend/ui/stock_detail_screen.dart';
import 'package:sg_dividend/ui/widgets/branded_app_bar.dart';
import 'package:sg_dividend/ui/widgets/industry_badge.dart';
import 'package:sg_dividend/ui/widgets/yield_methodology_dialog.dart';

enum _SortMode { yieldDesc, scoreAsc, alpha, priceDesc }

extension _SortLabel on _SortMode {
  String get label => switch (this) {
        _SortMode.yieldDesc => 'Yield ↓',
        _SortMode.scoreAsc => 'Risk ↑',
        _SortMode.alpha => 'A–Z',
        _SortMode.priceDesc => 'Price ↓',
      };
}

class StocksTab extends ConsumerStatefulWidget {
  const StocksTab({super.key});

  @override
  ConsumerState<StocksTab> createState() => _StocksTabState();
}

class _StocksTabState extends ConsumerState<StocksTab> {
  _SortMode _sort = _SortMode.yieldDesc;
  String _query = '';
  final Set<String> _industryFilter = {};

  @override
  void initState() {
    super.initState();
    // After first frame, consume any deep-link filter set from Home tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingFilter();
    });
  }

  void _applyPendingFilter() {
    final pending = ref.read(pendingIndustryFilterProvider);
    if (pending != null) {
      setState(() {
        _industryFilter
          ..clear()
          ..add(pending);
      });
      ref.read(pendingIndustryFilterProvider.notifier).state = null;
    }
  }

  List<Ticker> _filterSort(List<Ticker> tickers) {
    var list = tickers.where((t) {
      if (_industryFilter.isNotEmpty &&
          !_industryFilter.contains(t.industry.isEmpty ? t.sector : t.industry)) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return t.ticker.toLowerCase().contains(q) ||
          t.name.toLowerCase().contains(q) ||
          t.sector.toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case _SortMode.yieldDesc:
        list.sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
      case _SortMode.scoreAsc:
        list.sort((a, b) => a.score.compareTo(b.score));
      case _SortMode.alpha:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortMode.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // React to deep-links from Home (sector breakdown taps) — IndexedStack
    // keeps this State alive, so initState only fires once; ref.listen catches
    // subsequent changes.
    ref.listen<String?>(pendingIndustryFilterProvider, (_, next) {
      if (next != null) {
        setState(() {
          _industryFilter
            ..clear()
            ..add(next);
          _query = '';
        });
        ref.read(pendingIndustryFilterProvider.notifier).state = null;
      }
    });
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BrandedAppBar(subtitle: 'Stocks'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) {
          final allIndustries = <String>{};
          for (final t in u.tickers) {
            allIndustries.add(t.industry.isEmpty ? t.sector : t.industry);
          }
          final industries = allIndustries.toList()..sort();
          final filtered = _filterSort(u.tickers);
          return Column(children: [
            // ── Search + sort row ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.textTertiary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search ticker or name',
                            hintStyle: GoogleFonts.inter(
                                color: AppColors.textTertiary, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                _SortMenuButton(
                  value: _sort,
                  onChanged: (v) => setState(() => _sort = v),
                ),
              ]),
            ),

            // ── Industry filter chips ──────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _IndustryFilterChip(
                    label: 'All',
                    selected: _industryFilter.isEmpty,
                    onTap: () => setState(() => _industryFilter.clear()),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  for (final ind in industries) ...[
                    _IndustryFilterChip(
                      label: ind,
                      selected: _industryFilter.contains(ind),
                      onTap: () => setState(() {
                        if (_industryFilter.contains(ind)) {
                          _industryFilter.remove(ind);
                        } else {
                          _industryFilter.add(ind);
                        }
                      }),
                      color: IndustryBadge.colorFor(ind),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Column header row ──────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(children: [
                Text('NAME',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    )),
                const Spacer(),
                SizedBox(
                  width: 80,
                  child: Text('PRICE',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      )),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('YIELD',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          )),
                      const YieldInfoButton(),
                    ],
                  ),
                ),
              ]),
            ),

            // ── Stock rows ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No stocks match your filter.',
                        style: GoogleFonts.inter(
                            color: AppColors.textTertiary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                          indent: 16,
                          endIndent: 16),
                      itemBuilder: (context, i) {
                        final t = filtered[i];
                        return _StockRow(ticker: t);
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final Ticker ticker;
  const _StockRow({required this.ticker});

  @override
  Widget build(BuildContext context) {
    final t = ticker;
    final yield3y = t.threeYearCumulativeYieldPct;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StockDetailScreen(ticker: t)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Industry badge + ticker (stacked left, iFast Style)
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IndustryBadge(
                  industry: t.industry.isEmpty ? t.sector : t.industry,
                  fontSize: 9,
                ),
                const SizedBox(height: 4),
                Text(t.ticker,
                    style: GoogleFonts.robotoMono(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Name + sector
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.25)),
                  const SizedBox(height: 2),
                  Text('Risk ${t.score} · ${t.sector}',
                      style: GoogleFonts.inter(
                          color: AppColors.textTertiary, fontSize: 11)),
                ]),
          ),
          const SizedBox(width: 8),
          // Price (right-aligned)
          SizedBox(
            width: 80,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('S\$${t.price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('lot ${t.lotSize}',
                      style: GoogleFonts.inter(
                          color: AppColors.textTertiary, fontSize: 10)),
                ]),
          ),
          // Yield + 3y cumulative
          SizedBox(
            width: 80,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${t.yieldPct.toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${yield3y.toStringAsFixed(1)}% 3y',
                      style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _IndustryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _IndustryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final _SortMode value;
  final ValueChanged<_SortMode> onChanged;
  const _SortMenuButton({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortMode>(
      initialValue: value,
      onSelected: onChanged,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border)),
      itemBuilder: (_) => [
        for (final m in _SortMode.values)
          PopupMenuItem(
              value: m,
              child: Text(m.label,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 13))),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sort_rounded,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(value.label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ]),
      ),
    );
  }
}
