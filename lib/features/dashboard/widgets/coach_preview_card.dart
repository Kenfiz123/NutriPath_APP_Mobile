import 'package:flutter/material.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class CoachPreviewCard extends StatefulWidget {
  const CoachPreviewCard({required this.api, super.key});
  final ApiClient api;

  @override
  State<CoachPreviewCard> createState() => _CoachPreviewCardState();
}

class _CoachPreviewCardState extends State<CoachPreviewCard> {
  late Future<List<WeeklyCoachPlan>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getWeeklyCoachPlans();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WeeklyCoachPlan>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return NutriCard(
            color: AppColors.amber.withValues(alpha: 0.1),
            child: Column(
              children: [
                const SectionHeader(
                  title: 'AI Coach',
                  subtitle: 'Tạo kế hoạch ăn uống 7 ngày ngay bây giờ.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await widget.api.createWeeklyCoachPlan();
                    setState(() {
                      _future = widget.api.getWeeklyCoachPlans();
                    });
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Tạo kế hoạch tuần'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                  ),
                ),
              ],
            ),
          );
        }
        final plan = snapshot.data!.first;
        return NutriCard(
          color: AppColors.amber.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeader(title: 'AI Coach Plan'),
                  IconButton(
                    onPressed: () => setState(() {
                      _future = widget.api.getWeeklyCoachPlans();
                    }),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final step in plan.actionSteps.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
