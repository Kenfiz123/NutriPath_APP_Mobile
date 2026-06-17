import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.data, super.key});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final n = data.nutrition;
    final waterTargetMl = n.targets.waterMl > 0
        ? n.targets.waterMl.round()
        : data.member.waterTargetGlasses * 250;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        MetricCard(
          label: AppStrings.calories,
          value: formatNumber(n.totals.calories),
          icon: Icons.local_fire_department,
          accent: AppColors.orange,
          caption: 'mục tiêu ${formatNumber(n.targets.calories)}',
        ),
        MetricCard(
          label: AppStrings.protein,
          value: '${n.totals.protein.round()}g',
          icon: Icons.fitness_center,
          accent: AppColors.blue,
          caption: 'cần ${n.targets.protein.round()}g',
        ),
        MetricCard(
          label: AppStrings.water,
          value: '${formatNumber(data.mealLog.waterMl)} ml',
          icon: Icons.water_drop,
          accent: AppColors.teal,
          caption: 'cần ${formatNumber(waterTargetMl)} ml',
        ),
      ],
    );
  }
}
