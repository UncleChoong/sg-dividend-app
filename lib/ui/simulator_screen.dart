import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sg_dividend/data/models.dart';
import 'package:sg_dividend/domain/simulator.dart';
import 'package:sg_dividend/ui/widgets/disclaimer_banner.dart';
import 'package:sg_dividend/ui/widgets/projection_chart.dart';

class SimulatorScreen extends StatelessWidget {
  final Allocation alloc;
  final int horizonYears;
  final bool drip;
  final int monthlySgd;

  const SimulatorScreen({
    super.key, required this.alloc, required this.horizonYears,
    required this.drip, required this.monthlySgd,
  });

  @override
  Widget build(BuildContext context) {
    final withDrip = simulate(alloc, horizonYears: horizonYears, drip: true, monthlySgd: monthlySgd);
    final withoutDrip = simulate(alloc, horizonYears: horizonYears, drip: false, monthlySgd: monthlySgd);
    final fmt = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Forward Projection')),
      bottomNavigationBar: const SafeArea(child: DisclaimerBanner()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Assumes weighted yield ${alloc.weightedYieldPct.toStringAsFixed(2)}% stays constant. '
               'Past payments do not guarantee future ones.',
               style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ProjectionChart(withDrip: withDrip, withoutDrip: withoutDrip),
          const SizedBox(height: 12),
          Row(children: const [
            _LegendDot(color: Colors.teal, label: 'With DRIP'),
            SizedBox(width: 16),
            _LegendDot(color: Colors.grey, label: 'No DRIP'),
          ]),
          const SizedBox(height: 24),
          DataTable(
            columns: const [
              DataColumn(label: Text('Year')),
              DataColumn(label: Text('DRIP total')),
              DataColumn(label: Text('No DRIP total')),
            ],
            rows: [
              for (var i = 0; i < withDrip.length; i++)
                DataRow(cells: [
                  DataCell(Text('${withDrip[i].year}')),
                  DataCell(Text(fmt.format(withDrip[i].total))),
                  DataCell(Text(fmt.format(withoutDrip[i].total))),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label),
      ]);
}
