import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/action_row.dart';
import '../widgets/ai_tips_card.dart';
import '../widgets/coach_preview_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/progress_card.dart';
import '../widgets/stats_grid.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<DashboardData>? _future;

  void _reload() => setState(() {
        _future = ref
            .read(apiClientProvider)
            .getDashboard(date: localDateString());
      });

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isLoggedIn) return const LoginPrompt();
    final future = _future ??=
        ref.read(apiClientProvider).getDashboard(date: localDateString());

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<DashboardData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NutriPage(
              children: [
                ErrorPanel(error: snapshot.error!, onRetry: _reload)
              ],
            );
          }
          if (!snapshot.hasData) return const LoadingPanel();
          final data = snapshot.data!;
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
