import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets.dart';

class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({required this.analytics, super.key});

  final JsonMap analytics;

  @override
  Widget build(BuildContext context) {
    final daily = jsonMapList(analytics['dailyMeals']);
    final top = jsonMapList(analytics['topDishes']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader(title: 'Meal activity 7 ngày'),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: [
                for (var i = 0; i < daily.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: asDouble(daily[i]['meals']),
                        color: AppColors.primary,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Top món'),
        for (final dish in top.take(8))
          KeyValueLine(
            label: '#${asInt(dish['rank'])} ${asString(dish['dish'])}',
            value: '${asInt(dish['searches'])} lượt',
            icon: Icons.restaurant,
          ),
      ],
    );
  }
}
