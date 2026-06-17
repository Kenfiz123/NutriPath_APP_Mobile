import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/admin_ai_security_tab.dart';
import '../widgets/admin_analytics_tab.dart';
import '../widgets/admin_content_tab.dart';
import '../widgets/admin_overview_tab.dart';
import '../widgets/admin_system_tab.dart';
import '../widgets/admin_text_search_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const FullAdminScreen();
  }
}

class FullAdminScreen extends ConsumerStatefulWidget {
  const FullAdminScreen({super.key});

  @override
  ConsumerState<FullAdminScreen> createState() => _FullAdminScreenState();
}

class _FullAdminScreenState extends ConsumerState<FullAdminScreen> {
  late Future<_AdminBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminBundle> _load() async {
    final api = ref.read(apiClientProvider);
    final results = await Future.wait<Object>([
      api.getAdminOverview(),
      api.getAdminUsers(),
      api.getAdminContent(),
      api.getAdminAnalytics(),
      api.getAdminSystem(),
      api.getAdminAiSettings(),
      api.getAdminSecurity(),
      api.getAdminAiSafetyLogs(),
    ]);
    return _AdminBundle(
      overview: results[0] as AdminOverview,
      users: results[1] as JsonMap,
      content: results[2] as JsonMap,
      analytics: results[3] as JsonMap,
      system: results[4] as JsonMap,
      aiSettings: results[5] as JsonMap,
      security: results[6] as JsonMap,
      safetyLogs: results[7] as JsonMap,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminBundle>(
      future: _future,
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
        return DefaultTabController(
          length: 6,
          child: NutriPage(
            children: [
              SectionHeader(
                title: 'Admin',
                subtitle: 'Quản trị user, content, analytics, AI và bảo mật.',
                action: IconButton.filledTonal(
                  tooltip: 'Tải lại',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Users'),
                  Tab(text: 'Content'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'AI'),
                  Tab(text: 'System'),
                ],
              ),
              SizedBox(
                height: 720,
                child: TabBarView(
                  children: [
                    AdminOverviewTab(overview: data.overview),
                    AdminTextSearchTab(users: data.users),
                    AdminContentTab(content: data.content),
                    AdminAnalyticsTab(analytics: data.analytics),
                    AdminAiSecurityTab(
                      aiSettings: data.aiSettings,
                      security: data.security,
                      safetyLogs: data.safetyLogs,
                      onToggleAi: _updateAiSetting,
                      onToggleSecurity: _updateSecurity,
                    ),
                    AdminSystemTab(system: data.system),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAiSetting(String key, bool value) async {
    await ref.read(apiClientProvider).updateAdminAiSettings({key: value});
    _reload();
  }

  Future<void> _updateSecurity(String key, bool value) async {
    await ref.read(apiClientProvider).updateAdminSecurity({key: value});
    _reload();
  }
}

class _AdminBundle {
  const _AdminBundle({
    required this.overview,
    required this.users,
    required this.content,
    required this.analytics,
    required this.system,
    required this.aiSettings,
    required this.security,
    required this.safetyLogs,
  });

  final AdminOverview overview;
  final JsonMap users;
  final JsonMap content;
  final JsonMap analytics;
  final JsonMap system;
  final JsonMap aiSettings;
  final JsonMap security;
  final JsonMap safetyLogs;
}
