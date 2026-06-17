import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class CalculatorResultCard extends StatelessWidget {
  const CalculatorResultCard({required this.result, super.key});

  final CalorieCalculation result;

  @override
  Widget build(BuildContext context) {
    final r = result.results;
    final macros = asJsonMap(r['macroTargets']);
    return NutriCard(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Kết quả ước tính'),
          KeyValueLine(label: 'BMR', value: '${asInt(r['bmr'])} kcal'),
          KeyValueLine(label: 'TDEE', value: '${asInt(r['tdee'])} kcal'),
          KeyValueLine(
            label: 'Mục tiêu/ngày',
            value: '${asInt(r['calorieGoal'])} kcal',
          ),
          KeyValueLine(
            label: 'BMI',
            value: asDouble(r['bmi']).toStringAsFixed(1),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Protein ${asInt(macros['protein'])}g')),
              Chip(label: Text('Carbs ${asInt(macros['carbs'])}g')),
              Chip(label: Text('Fat ${asInt(macros['fat'])}g')),
            ],
          ),
          if (result.aiInsight != null) ...[
            const SizedBox(height: 12),
            Text(
              asString(result.aiInsight!['summary']),
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
