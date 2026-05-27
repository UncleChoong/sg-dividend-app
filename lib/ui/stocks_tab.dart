import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/splash_screen.dart';
import 'package:sg_dividend/ui/stock_detail_screen.dart';

enum _SortMode { yieldDesc, scoreAsc, alpha }

class StocksTab extends ConsumerStatefulWidget {
  const StocksTab({super.key});

  @override
  ConsumerState<StocksTab> createState() => _StocksTabState();
}

class _StocksTabState extends ConsumerState<StocksTab> {
  _SortMode _sort = _SortMode.yieldDesc;

  List<Ticker> _sorted(List<Ticker> tickers) {
    final list = [...tickers];
    switch (_sort) {
      case _SortMode.yieldDesc:
        list.sort((a, b) => b.yieldPct.compareTo(a.yieldPct));
      case _SortMode.scoreAsc:
        list.sort((a, b) => a.score.compareTo(b.score));
      case _SortMode.alpha:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stocks'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<_SortMode>(
              value: _sort,
              dropdownColor: AppColors.surfaceElevated,
              style:
                  GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              icon: const Icon(Icons.sort_rounded,
                  color: AppColors.textSecondary, size: 20),
              items: const [
                DropdownMenuItem(
                    value: _SortMode.yieldDesc, child: Text('Yield ↓')),
                DropdownMenuItem(
                    value: _SortMode.scoreAsc, child: Text('Score ↑')),
                DropdownMenuItem(value: _SortMode.alpha, child: Text('A–Z')),
              ],
              onChanged: (v) => setState(() => _sort = v!),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) {
          final sorted = _sorted(u.tickers);
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: 16,
                endIndent: 16),
            itemBuilder: (context, i) {
              final t = sorted[i];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => StockDetailScreen(ticker: t)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    // Ticker code — monospace via fontFamily
                    SizedBox(
                      width: 56,
                      child: Text(
                        t.ticker,
                        style: GoogleFonts.robotoMono(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + sector
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(t.sector,
                                style: GoogleFonts.inter(
                                    color: AppColors.textTertiary,
                                    fontSize: 11)),
                          ]),
                    ),
                    const SizedBox(width: 10),
                    // Price + 3y cum yield
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('S\$${t.price.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                          '${t.threeYearCumulativeYieldPct.toStringAsFixed(1)}% 3y',
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
