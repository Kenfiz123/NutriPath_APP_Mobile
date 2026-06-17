import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

class AdminTextSearchTab extends StatelessWidget {
  const AdminTextSearchTab({required this.users, super.key});

  final JsonMap users;

  @override
  Widget build(BuildContext context) {
    final items = embeddedList(users, 'users');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '${items.length} tài khoản',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (final user in items)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(asString(user['name'])),
            subtitle: Text(
              '${asString(user['email'])} • ${asString(user['role'])}',
            ),
            trailing: TierChip(tier: asString(user['tier'], 'free')),
          ),
      ],
    );
  }
}
