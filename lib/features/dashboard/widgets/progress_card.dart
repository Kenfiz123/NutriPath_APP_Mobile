import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({required this.n, super.key});
  final MealSummary n;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Hôm nay'),
          const SizedBox(height: 16),
          ProgressLine(
            value: n.totals.calories / n.targets.calories,
            height: 12,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${n.calorieProgressPct}% mục tiêu',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Còn ${formatNumber(n.remainingCalories)} kcal',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
