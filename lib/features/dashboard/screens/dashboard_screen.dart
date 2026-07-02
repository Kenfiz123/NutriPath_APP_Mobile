import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/widgets.dart';
import '../widgets/action_row.dart';
import '../widgets/ai_tips_card.dart';
import '../widgets/coach_preview_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/stats_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isLoggedIn) return const LoginPrompt();

    final date = localDateString();
    final asyncData = ref.watch(dashboardDataProvider(date));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardDataProvider(date).future),
      child: asyncData.when(
        loading: () => const LoadingPanel(),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.refresh(dashboardDataProvider(date)),
            ),
          ],
        ),
        data: (data) {
          final n = data.nutrition;
          return NutriPage(
            children: [
              GreetingHeader(data: data),
              StatsGrid(data: data),
              ProgressCard(n: n),
              AITipsCard(tips: data.tips),
              const ActionRow(),
              if (data.member.canUseCoach)
                CoachPreviewCard(api: ref.read(apiClientProvider))
              else
                const LockedPanel(
                  title: 'Mở khóa AI Coach',
                  message: 'Kế hoạch ăn uống cá nhân hóa dành riêng cho SVIP.',
                ),
            ],
          );
        },
      ),
    );
  }
}
