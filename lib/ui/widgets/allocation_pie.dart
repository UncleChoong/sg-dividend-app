import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sg_dividend/data/models.dart';

class AllocationPie extends StatelessWidget {
  final Allocation alloc;
  const AllocationPie({super.key, required this.alloc});

  @override
  Widget build(BuildContext context) {
    final palette = [
      Colors.teal, Colors.indigo, Colors.amber, Colors.deepOrange, Colors.purple,
      Colors.green, Colors.blueGrey, Colors.pink, Colors.brown, Colors.cyan,
    ];
    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          for (var i = 0; i < alloc.lines.length; i++)
            PieChartSectionData(
              value: alloc.lines[i].sgdAllocated,
              color: palette[i % palette.length],
              title: alloc.lines[i].ticker.ticker,
              titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
              radius: 60,
            ),
        ],
      )),
    );
  }
}
