import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NutritionReport>(
      future: ref.read(apiClientProvider).getNutritionReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPanel();
        final rep = snapshot.data!;
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Báo cáo tuần',
              subtitle: 'Phân tích thói quen ăn uống của bạn.',
            ),
            NutriCard(
              child: Column(
                children: [
                  const Text(
                    'Calo trung bình ngày',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${rep.averages['calories'].round()} kcal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Phân tích AI'),
                  const SizedBox(height: 12),
                  for (final ins in rep.insights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $ins',
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
