import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sg_dividend/data/models.dart';

class ProjectionChart extends StatelessWidget {
  final List<SimulationPoint> withDrip;
  final List<SimulationPoint> withoutDrip;

  const ProjectionChart({super.key, required this.withDrip, required this.withoutDrip});

  @override
  Widget build(BuildContext context) {
    final maxY = [...withDrip, ...withoutDrip].map((p) => p.total).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 260,
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY * 1.05,
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 56)),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            color: Colors.teal,
            barWidth: 3,
            spots: withDrip.map((p) => FlSpot(p.year.toDouble(), p.total)).toList(),
          ),
          LineChartBarData(
            isCurved: false,
            color: Colors.grey,
            barWidth: 2,
            spots: withoutDrip.map((p) => FlSpot(p.year.toDouble(), p.total)).toList(),
          ),
        ],
      )),
    );
  }
}
