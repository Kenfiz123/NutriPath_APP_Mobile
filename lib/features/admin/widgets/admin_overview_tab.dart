import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({required this.overview, super.key});

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final kpi in overview.kpis)
          MetricCard(
            label: asString(kpi['label']),
            value: asString(kpi['value']),
            caption: asString(kpi['delta']),
            icon: Icons.insights,
          ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Người dùng mới'),
        for (final user in overview.recentUsers)
          ListTile(
            title: Text(asString(user['name'])),
            subtitle: Text(asString(user['email'])),
            trailing: Text(asString(user['tier']).toUpperCase()),
          ),
      ],
    );
  }
}
