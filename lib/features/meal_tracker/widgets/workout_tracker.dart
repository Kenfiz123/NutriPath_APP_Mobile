import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class WorkoutTracker extends ConsumerWidget {
  const WorkoutTracker({
    required this.log,
    required this.onUpdate,
    super.key,
  });

  final MealLog log;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = jsonMapList(log.activity['workouts']);
    final calories = asDouble(log.activity['workoutCalories']);
    final minutes = asInt(log.activity['workoutMinutes']);

    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Vận động',
            subtitle: '${formatNumber(calories)} kcal đã đốt • $minutes phút',
            action: IconButton.filledTonal(
              tooltip: 'Ghi bài tập',
              onPressed: () => _addWorkout(context, ref),
              icon: const Icon(Icons.add),
            ),
          ),
          if (workouts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Chưa có bài tập nào hôm nay.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final workout in workouts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.fitness_center, color: AppColors.blue),
                ),
                title: Text(
                  asString(workout['label'], 'Bài tập'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${asInt(workout['durationMinutes'])} phút • ${asString(workout['intensity'], 'moderate')}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${asInt(workout['calories'])} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      tooltip: 'Xóa bài tập',
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        try {
                          await ref
                              .read(apiClientProvider)
                              .deleteWorkout(log.date, asString(workout['id']));
                          onUpdate();
                        } catch (e) {
                          if (context.mounted) {
                            showSnack(context, readableError(e));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addWorkout(BuildContext context, WidgetRef ref) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const WorkoutDialog(),
    );
    if (payload == null) return;
    try {
      await ref.read(apiClientProvider).addWorkout(log.date, payload);
      onUpdate();
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class WorkoutDialog extends StatefulWidget {
  const WorkoutDialog({super.key});

  @override
  State<WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<WorkoutDialog> {
  final _duration = TextEditingController(text: '30');
  final _distance = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'walking';
  String _intensity = 'moderate';

  @override
  void dispose() {
    _duration.dispose();
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ghi bài tập'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Loại bài tập'),
              items: const [
                DropdownMenuItem(value: 'walking', child: Text('Đi bộ')),
                DropdownMenuItem(value: 'running', child: Text('Chạy bộ')),
                DropdownMenuItem(value: 'cycling', child: Text('Đạp xe')),
                DropdownMenuItem(value: 'gym', child: Text('Gym')),
                DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
                DropdownMenuItem(value: 'swimming', child: Text('Bơi')),
                DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                DropdownMenuItem(value: 'custom', child: Text('Khác')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thời lượng phút'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distance,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quãng đường km',
                hintText: 'Tùy chọn',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _intensity,
              decoration: const InputDecoration(labelText: 'Cường độ'),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'hard', child: Text('Nặng')),
                DropdownMenuItem(value: 'very_hard', child: Text('Rất nặng')),
              ],
              onChanged: (value) =>
                  setState(() => _intensity = value ?? _intensity),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ví dụ: chạy dốc, nhịp tim cao...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final duration = int.tryParse(_duration.text.trim()) ?? 0;
            if (duration <= 0) return;
            final payload = <String, dynamic>{
              'type': _type,
              'durationMinutes': duration,
              'intensity': _intensity,
              'notes': _notes.text.trim(),
            };
            final distance = double.tryParse(_distance.text.trim());
            if (distance != null && distance > 0) {
              payload['distanceKm'] = distance;
            }
            Navigator.pop(context, payload);
          },
          child: const Text('Lưu bài tập'),
        ),
      ],
    );
  }
}
