import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class WaterTracker extends ConsumerWidget {
  const WaterTracker({
    required this.log,
    required this.onUpdate,
    this.onOptimisticUpdate,
    super.key,
  });

  static const _waterStepMl = 250;

  final MealLog log;
  final ValueChanged<MealLog> onUpdate;
  final ValueChanged<MealLog>? onOptimisticUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetFromSummary = log.summary.targets.waterMl.round();
    final target = targetFromSummary > 0
        ? targetFromSummary
        : (log.summary.targets.waterGlasses * _waterStepMl).round();
    final current = log.waterMl;
    final progressTarget = target <= 0 ? _waterStepMl : target;

    return NutriCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: AppColors.teal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uống nước',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '${formatNumber(current)} / ${formatNumber(progressTarget)} ml',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                ProgressLine(
                  value: current / progressTarget,
                  color: AppColors.teal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                onPressed: current > 0
                    ? () => _setWaterMl(
                        context,
                        ref,
                        current - _waterStepMl < 0 ? 0 : current - _waterStepMl,
                      )
                    : null,
                tooltip: 'Giảm 250 ml',
                icon: const Icon(Icons.remove_circle_outline),
              ),
              TextButton(
                onPressed: () => _addWaterMl(context, ref, _waterStepMl),
                child: const Text('+250 ml'),
              ),
              IconButton(
                tooltip: 'Nhập ml',
                onPressed: () => _showAddWaterDialog(context, ref),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setWaterMl(
    BuildContext context,
    WidgetRef ref,
    int waterMl,
  ) async {
    final previous = log;
    onOptimisticUpdate?.call(_withWaterMl(waterMl));
    try {
      final updated = await ref
          .read(apiClientProvider)
          .updateWaterMl(log.date, waterMl);
      onUpdate(updated);
    } catch (e) {
      onOptimisticUpdate?.call(previous);
      if (context.mounted) showSnack(context, readableError(e));
    }
  }

  Future<void> _addWaterMl(
    BuildContext context,
    WidgetRef ref,
    int amountMl,
  ) async {
    final previous = log;
    onOptimisticUpdate?.call(_withWaterMl(log.waterMl + amountMl));
    try {
      final updated = await ref
          .read(apiClientProvider)
          .addWaterMl(log.date, amountMl);
      onUpdate(updated);
    } catch (e) {
      onOptimisticUpdate?.call(previous);
      if (context.mounted) showSnack(context, readableError(e));
    }
  }

  MealLog _withWaterMl(int value) {
    final waterMl = value < 0 ? 0 : value;
    final targetFromSummary = log.summary.targets.waterMl.round();
    final target = targetFromSummary > 0
        ? targetFromSummary
        : (log.summary.targets.waterGlasses * _waterStepMl).round();
    final updatedGoals = log.goals.map((goal) {
      if (asString(goal['id']) != 'water') return goal;
      return <String, dynamic>{
        ...goal,
        'done': target > 0 && waterMl >= target,
      };
    }).toList();
    return MealLog(
      id: log.id,
      memberId: log.memberId,
      date: log.date,
      waterMl: waterMl,
      waterGlasses: (waterMl / _waterStepMl).round(),
      activity: log.activity,
      goals: updatedGoals,
      meals: log.meals,
      summary: log.summary,
      access: log.access,
    );
  }

  Future<void> _showAddWaterDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: '250');
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nước'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Số ml',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(context, value);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0) return;
    if (!context.mounted) return;
    await _addWaterMl(context, ref, amount);
  }
}
