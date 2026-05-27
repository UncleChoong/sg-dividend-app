import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/optimizer.dart';
import 'package:sg_dividend/ui/explain_screen.dart';
import 'package:sg_dividend/ui/simulator_screen.dart';
import 'package:sg_dividend/ui/widgets/allocation_pie.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';

class ResultScreen extends StatelessWidget {
  final Universe universe;
  final int capital;
  final RiskLevel risk;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;

  const ResultScreen({
    super.key, required this.universe, required this.capital,
    required this.risk, required this.horizonYears,
    required this.drip, required this.monthlySgd,
  });

  @override
  Widget build(BuildContext context) {
    final alloc = optimize(capitalSgd: capital, risk: risk, universe: universe);
    final fmt = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    if (alloc.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Try at least S\$1,000 to build a diversified basket on SGX board lots.',
            style: TextStyle(fontSize: 16), textAlign: TextAlign.center,
          ),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Forward projection',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SimulatorScreen(
                    alloc: alloc, horizonYears: horizonYears,
                    drip: drip, monthlySgd: monthlySgd))),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Why these?',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ExplainScreen(alloc: alloc, risk: risk))),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Projected annual dividend',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(fmt.format(alloc.projectedAnnualIncome),
                  style: Theme.of(context).textTheme.displaySmall),
              Text('${alloc.weightedYieldPct.toStringAsFixed(2)}% weighted yield  ·  '
                   'Invested ${fmt.format(alloc.totalCapital)}  ·  '
                   'Cash ${fmt.format(alloc.cashLeftover)}'),
            ]),
          )),
          const SizedBox(height: 16),
          AllocationPie(alloc: alloc),
          const SizedBox(height: 16),
          ...alloc.lines.map((l) => ListTile(
                title: Text('${l.ticker.ticker}  ·  ${l.ticker.name}'),
                subtitle: Text('${l.lots} lots  ·  ${(l.sgdAllocated/alloc.totalCapital*100).toStringAsFixed(1)}%'),
                trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(fmt.format(l.sgdAllocated)),
                  Text('+${fmt.format(l.projectedAnnualIncome)}/yr',
                      style: const TextStyle(fontSize: 12, color: Colors.green)),
                ]),
              )),
        ],
      ),
    );
  }
}
