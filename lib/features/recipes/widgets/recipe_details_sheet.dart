import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

Future<void> showRecipeDetails(BuildContext context, Recipe r) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            r.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _rChip(Icons.timer_outlined, '${r.timeMinutes} phút'),
              const SizedBox(width: 8),
              _rChip(
                Icons.local_fire_department_outlined,
                '${r.calories.round()} kcal',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Nguyên liệu'),
          for (final i in r.ingredients)
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 6),
              title: Text('${asString(i['name'])}: ${asString(i['amount'])}'),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Hướng dẫn'),
          for (var i = 0; i < r.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${i + 1}. ${r.steps[i]}',
                style: const TextStyle(height: 1.5),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _rChip(IconData i, String l) => Chip(
      avatar: Icon(i, size: 14),
      label: Text(l, style: const TextStyle(fontSize: 12)),
    );
