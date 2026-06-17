import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/constants/app_colors.dart';

class AdminSystemTab extends StatelessWidget {
  const AdminSystemTab({required this.system, super.key});

  final JsonMap system;

  @override
  Widget build(BuildContext context) {
    final services = jsonMapList(system['services']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final service in services)
          ListTile(
            leading: Icon(
              asString(service['status']).toLowerCase().contains('ok')
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: asString(service['status']).toLowerCase().contains('ok')
                  ? AppColors.emerald
                  : AppColors.amber,
            ),
            title: Text(asString(service['name'])),
            subtitle: Text(
              asString(service['description'], asString(service['status'])),
            ),
            trailing: Text(asString(service['status']).toUpperCase()),
          ),
      ],
    );
  }
}
