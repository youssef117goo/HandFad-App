// HandFab App — sensor_chart.dart
// Real-time 3-axis accelerometer chart using fl_chart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SensorChart extends StatelessWidget {
  final List<double> axHistory;
  final List<double> ayHistory;
  final List<double> azHistory;

  const SensorChart({
    super.key,
    required this.axHistory,
    required this.ayHistory,
    required this.azHistory,
  });

  List<FlSpot> _toSpots(List<double> data) {
    return List.generate(data.length,
        (i) => FlSpot(i.toDouble(), data[i].clamp(-3.0, 3.0)));
  }

  LineChartBarData _line(List<double> data, Color color) {
    return LineChartBarData(
      spots: _toSpots(data),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 1.8,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.06),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (axHistory.isEmpty) {
      return Center(
        child: Text('Waiting for data…',
            style: TextStyle(color: Colors.white.withOpacity(0.3))),
      );
    }

    return LineChart(
      LineChartData(
        minY: -3, maxY: 3,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(
              color: Colors.white.withOpacity(0.03), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A2235),
          ),
        ),
        lineBarsData: [
          _line(axHistory, const Color(0xFF00D4FF)),   // AX = Cyan
          _line(ayHistory, const Color(0xFF7B61FF)),   // AY = Purple
          _line(azHistory, const Color(0xFF00FF87)),   // AZ = Green
        ],
      ),
      duration: const Duration(milliseconds: 0), // no animation for performance
    );
  }
}
