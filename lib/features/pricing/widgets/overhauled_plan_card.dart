import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class OverhauledPlanCard extends StatelessWidget {
  const OverhauledPlanCard({required this.plan, super.key});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.id == 'svip'
        ? AppColors.amber
        : (plan.id == 'vip' ? AppColors.emerald : AppColors.blue);
    return NutriCard(
      color: color.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              TierChip(tier: plan.id),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Text(
            plan.id == 'free' ? '0đ' : formatVnd(plan.monthlyPrice),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          for (final f in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    asBool(f['included'])
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: asBool(f['included']) ? color : AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    asString(f['label']),
                    style: TextStyle(
                      color: asBool(f['included']) ? null : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (plan.id != 'free')
            FilledButton(
              onPressed: () =>
                  context.go('${AppRoutes.checkout}?plan=${plan.id}&billing=monthly'),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Nâng cấp ngay'),
            ),
        ],
      ),
    );
  }
}
