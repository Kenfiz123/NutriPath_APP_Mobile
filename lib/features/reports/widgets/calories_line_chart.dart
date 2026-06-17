import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/constants/app_colors.dart';

class CaloriesLineChart extends StatelessWidget {
  const CaloriesLineChart({required this.daily, super.key});

  final List<JsonMap> daily;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < daily.length; i++) {
      spots.add(FlSpot(i.toDouble(), asDouble(daily[i]['calories'])));
    }
    if (spots.isEmpty) {
      return const Center(child: Text('Chưa đủ dữ liệu để vẽ biểu đồ.'));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            color: AppColors.primary,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
