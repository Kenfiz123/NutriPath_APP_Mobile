import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

class AdminAiSecurityTab extends StatelessWidget {
  const AdminAiSecurityTab({
    required this.aiSettings,
    required this.security,
    required this.safetyLogs,
    required this.onToggleAi,
    required this.onToggleSecurity,
    super.key,
  });

  final JsonMap aiSettings;
  final JsonMap security;
  final JsonMap safetyLogs;
  final Future<void> Function(String key, bool value) onToggleAi;
  final Future<void> Function(String key, bool value) onToggleSecurity;

  @override
  Widget build(BuildContext context) {
    final settings = asJsonMap(aiSettings['settings']);
    final securityMap = asJsonMap(security['security']);
    final logs = jsonMapList(safetyLogs['logs']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader(title: 'AI settings'),
        for (final entry in settings.entries)
          AdminSettingTile(entry: entry, onToggle: onToggleAi),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Security'),
        for (final entry in securityMap.entries)
          AdminSettingTile(entry: entry, onToggle: onToggleSecurity),
        const SizedBox(height: 12),
        SectionHeader(title: 'AI safety logs (${logs.length})'),
        for (final log in logs.take(8))
          ListTile(
            title: Text(asString(log['reason'], asString(log['type'], 'Log'))),
            subtitle: Text(asString(log['createdAt'])),
            trailing: Text(asString(log['severity'], 'info')),
          ),
      ],
    );
  }
}

class AdminSettingTile extends StatelessWidget {
  const AdminSettingTile({required this.entry, required this.onToggle, super.key});

  final MapEntry<String, dynamic> entry;
  final Future<void> Function(String key, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (entry.value is bool) {
      return SwitchListTile(
        title: Text(entry.key),
        value: entry.value as bool,
        onChanged: (value) => onToggle(entry.key, value),
      );
    }
    return KeyValueLine(label: entry.key, value: asString(entry.value));
  }
}
