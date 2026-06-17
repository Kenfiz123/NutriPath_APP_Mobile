import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

class AdminContentTab extends StatelessWidget {
  const AdminContentTab({required this.content, super.key});

  final JsonMap content;

  @override
  Widget build(BuildContext context) {
    final foods = jsonMapList(content['foods']);
    final recipes = jsonMapList(content['recipes']);
    final plans = jsonMapList(content['mealPlans']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Foods',
                value: '${foods.length}',
                icon: Icons.fastfood,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Recipes',
                value: '${recipes.length}',
                icon: Icons.menu_book,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Plan content'),
        for (final plan in plans)
          KeyValueLine(
            label: asString(plan['name']),
            value: '${asInt(plan['meals'])} quyền',
            icon: Icons.workspace_premium,
          ),
      ],
    );
  }
}
