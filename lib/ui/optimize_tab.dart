import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/result_screen.dart';
import 'package:sg_dividend/ui/splash_screen.dart';
import 'package:sg_dividend/ui/widgets/branded_app_bar.dart';

const _kAllIndustries = [
  'Banks',
  'REITs',
  'Telco',
  'Utilities',
  'Industrials',
  'Consumer',
  'Business Trusts',
  'Other',
];

class OptimizeTab extends ConsumerStatefulWidget {
  const OptimizeTab({super.key});

  @override
  ConsumerState<OptimizeTab> createState() => _OptimizeTabState();
}

class _OptimizeTabState extends ConsumerState<OptimizeTab> {
  final _capitalCtrl = TextEditingController(text: '10000');
  final _monthlyCtrl = TextEditingController(text: '0');
  RiskLevel _risk = RiskLevel.neutral;
  int _horizon = 5;
  bool _drip = true;
  final Set<String> _selectedIndustries = Set.from(_kAllIndustries);

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(universeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BrandedAppBar(subtitle: 'Optimize'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (universe) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _InputCard(
              label: 'CAPITAL',
              child: TextField(
                controller: _capitalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  prefixText: 'S\$ ',
                  prefixStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: '10000',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'RISK LEVEL',
              child: SegmentedButton<RiskLevel>(
                segments: const [
                  ButtonSegment(
                      value: RiskLevel.conservative,
                      label: Text('Conservative')),
                  ButtonSegment(
                      value: RiskLevel.neutral, label: Text('Neutral')),
                  ButtonSegment(
                      value: RiskLevel.aggressive, label: Text('Aggressive')),
                ],
                selected: {_risk},
                onSelectionChanged: (s) => setState(() => _risk = s.first),
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'HORIZON (YEARS)',
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1y')),
                  ButtonSegment(value: 5, label: Text('5y')),
                  ButtonSegment(value: 10, label: Text('10y')),
                  ButtonSegment(value: 20, label: Text('20y')),
                ],
                selected: {_horizon},
                onSelectionChanged: (s) => setState(() => _horizon = s.first),
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'DRIP',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reinvest dividends',
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('Compound returns by reinvesting payouts',
                              style: GoogleFonts.inter(
                                  color: AppColors.textTertiary, fontSize: 12)),
                        ]),
                  ),
                  Switch(
                      value: _drip,
                      onChanged: (v) => setState(() => _drip = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'MONTHLY CONTRIBUTION',
              child: TextField(
                controller: _monthlyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  prefixText: 'S\$ ',
                  prefixStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: '0 (optional)',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Industry filter
            _InputCard(
              label: 'INDUSTRIES (OPTIONAL)',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Include only selected sectors in the portfolio:',
                        style: GoogleFonts.inter(
                            color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kAllIndustries.map((ind) {
                        final selected = _selectedIndustries.contains(ind);
                        return FilterChip(
                          label: Text(ind),
                          selected: selected,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedIndustries.add(ind);
                              } else {
                                _selectedIndustries.remove(ind);
                              }
                            });
                          },
                          labelStyle: GoogleFonts.inter(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceElevated,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.border,
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        onPressed: () => setState(
                            () => _selectedIndustries.addAll(_kAllIndustries)),
                        child: Text('All',
                            style: GoogleFonts.inter(
                                color: AppColors.primary, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        onPressed: () =>
                            setState(() => _selectedIndustries.clear()),
                        child: Text('None',
                            style: GoogleFonts.inter(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(height: 32),

            // Optimize button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  final cap = int.tryParse(_capitalCtrl.text) ?? 0;
                  final monthly = int.tryParse(_monthlyCtrl.text) ?? 0;
                  // Pass null when all selected (no filtering)
                  final filter =
                      _selectedIndustries.length == _kAllIndustries.length
                          ? null
                          : Set<String>.from(_selectedIndustries);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ResultScreen(
                      universe: universe,
                      capital: cap,
                      risk: _risk,
                      horizonYears: _horizon,
                      drip: _drip,
                      monthlySgd: monthly,
                      includedIndustries: filter,
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('Optimize Portfolio',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InputCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
