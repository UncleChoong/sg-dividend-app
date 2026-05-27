import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sg_dividend/data/models.dart';
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
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Capital (S\$)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _capitalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'S\$ '),
          ),
          const SizedBox(height: 24),
          const Text('Risk level', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<RiskLevel>(
            segments: const [
              ButtonSegment(value: RiskLevel.conservative, label: Text('Conservative')),
              ButtonSegment(value: RiskLevel.neutral, label: Text('Neutral')),
              ButtonSegment(value: RiskLevel.aggressive, label: Text('Aggressive')),
            ],
            selected: {_risk},
            onSelectionChanged: (s) => setState(() => _risk = s.first),
          ),
          const SizedBox(height: 24),
          const Text('Horizon (years)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
            ],
            selected: {_horizon},
            onSelectionChanged: (s) => setState(() => _horizon = s.first),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Reinvest dividends (DRIP)'),
            value: _drip,
            onChanged: (v) => setState(() => _drip = v),
          ),
          const SizedBox(height: 8),
          const Text('Monthly contribution (optional, S\$)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _monthlyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'S\$ '),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              final cap = int.tryParse(_capitalCtrl.text) ?? 0;
              final monthly = int.tryParse(_monthlyCtrl.text) ?? 0;
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(
                    universe: widget.universe,
                    capital: cap,
                    risk: _risk,
                    horizonYears: _horizon,
                    drip: _drip,
                    monthlySgd: monthly,
                  )));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Optimize', style: TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
