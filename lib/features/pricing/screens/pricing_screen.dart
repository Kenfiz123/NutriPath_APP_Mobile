import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/overhauled_plan_card.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});
  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plan>>(
      future: ref.read(apiClientProvider).getPlans('monthly'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPanel();
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Nâng cấp hội viên',
              subtitle: 'Mở khóa toàn bộ tính năng AI.',
            ),
            for (final p in snapshot.data!) OverhauledPlanCard(plan: p),
          ],
        );
      },
    );
  }
}
