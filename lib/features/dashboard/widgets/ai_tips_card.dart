import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets.dart';

class AITipsCard extends StatelessWidget {
  const AITipsCard({required this.tips, super.key});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();
    return NutriCard(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gợi ý từ NutriBot',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in tips.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $tip',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
