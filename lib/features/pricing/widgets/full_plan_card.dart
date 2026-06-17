import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class FullPlanCard extends StatelessWidget {
  const FullPlanCard({required this.plan, required this.billing, super.key});

  final Plan plan;
  final String billing;

  @override
  Widget build(BuildContext context) {
    final color = switch (plan.id) {
      'svip' => AppColors.amber,
      'vip' => AppColors.emerald,
      _ => AppColors.blue,
    };
    final quote = plan.pricePreview;
    final price = quote?.total ?? plan.monthlyPrice;
    return NutriCard(
      color: color.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              TierChip(tier: plan.id),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.description),
          const SizedBox(height: 14),
          Text(
            plan.id == 'free' ? '0đ' : formatVnd(price),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(
            billing == 'annual'
                ? 'thanh toán theo năm'
                : 'thanh toán theo tháng',
          ),
          const SizedBox(height: 14),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    asBool(feature['included'])
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: asBool(feature['included'])
                        ? color
                        : AppColors.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(asString(feature['label']))),
                ],
              ),
            ),
          if (plan.id != 'free') ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.go('${AppRoutes.checkout}?plan=${plan.id}&billing=$billing'),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Chọn gói này'),
            ),
          ],
        ],
      ),
    );
  }
}
