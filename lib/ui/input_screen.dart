import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/theme.dart';
import 'package:sg_dividend/ui/result_screen.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class InputScreen extends StatefulWidget {
  final Universe universe;
  const InputScreen({super.key, required this.universe});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _capitalCtrl = TextEditingController(text: '10000');
  final _monthlyCtrl = TextEditingController(text: '0');
  RiskLevel _risk = RiskLevel.neutral;
  int _horizon = 5;
  bool _drip = true;

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SG Dividend Optimizer')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _InputCard(
            label: 'CAPITAL',
            child: TextField(
              controller: _capitalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
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
                ButtonSegment(value: RiskLevel.conservative, label: Text('Conservative')),
                ButtonSegment(value: RiskLevel.neutral, label: Text('Neutral')),
                ButtonSegment(value: RiskLevel.aggressive, label: Text('Aggressive')),
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
                    ],
                  ),
                ),
                Switch(
                  value: _drip,
                  onChanged: (v) => setState(() => _drip = v),
                ),
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
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                prefixText: 'S\$ ',
                prefixStyle: TextStyle(color: AppColors.textSecondary),
                hintText: '0 (optional)',
              ),
            ),
          ),
          const SizedBox(height: 32),
          _OptimizeButton(onPressed: () {
            final cap = int.tryParse(_capitalCtrl.text) ?? 0;
            final monthly = int.tryParse(_monthlyCtrl.text) ?? 0;
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ResultScreen(
                      universe: widget.universe,
                      capital: cap,
                      risk: _risk,
                      horizonYears: _horizon,
                      drip: _drip,
                      monthlySgd: monthly,
                    )));
          }),
          const SizedBox(height: 8),
        ]),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _OptimizeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _OptimizeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Optimize Portfolio',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
