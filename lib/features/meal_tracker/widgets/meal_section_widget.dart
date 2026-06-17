import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import 'custom_food_dialog.dart';
import 'food_picker_dialog.dart';
import 'text_icon_button.dart';

class MealSectionWidget extends ConsumerWidget {
  const MealSectionWidget({
    required this.meal,
    required this.date,
    required this.onUpdate,
    super.key,
  });
  final MealSection meal;
  final DateTime date;
  final ValueChanged<MealLog> onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = mealColor(meal.id);
    return NutriCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${meal.time} • mục tiêu ${meal.targetKcal.round()} kcal',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${meal.totalCalories.round()} kcal',
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
          if (meal.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Chưa có món ăn nào.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            for (final item in meal.items)
              ListTile(
                dense: true,
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${item.portion} • x${item.quantity.round()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.calories.round()} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        try {
                          final updated = await ref
                              .read(apiClientProvider)
                              .deleteMealItem(
                                localDateString(date),
                                meal.id,
                                item.id,
                              );
                          onUpdate(updated);
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextIconButton(
                  icon: Icons.search,
                  label: 'Tìm món',
                  onTap: () => _addFromLibrary(context, ref),
                ),
                TextIconButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Chụp ảnh',
                  onTap: () => _addFromPhoto(context, ref),
                ),
                TextIconButton(
                  icon: Icons.edit_note,
                  label: 'Tự nấu',
                  onTap: () => _addCustom(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFromLibrary(BuildContext context, WidgetRef ref) async {
    final food = await showDialog<Food>(
      context: context,
      builder: (context) => FoodPickerDialog(api: ref.read(apiClientProvider)),
    );
    if (food == null) return;
    try {
      final updated = await ref
          .read(apiClientProvider)
          .addMealItem(localDateString(date), meal.id, food.id);
      onUpdate(updated);
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }

  Future<void> _addFromPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final res = await ref
          .read(apiClientProvider)
          .estimateFoodPhoto(imageDataUrl: dataUrl);
      if (!context.mounted) return;

      final estimate = asJsonMap(res['estimate']);
      final addable = asJsonMap(res['addableItem']);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI nhận diện món ăn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                asString(estimate['dishName']),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text('${estimate['calories']} kcal • ${estimate['portion']}'),
              const SizedBox(height: 12),
              Text(
                'Độ tin cậy: ${(asDouble(estimate['confidence']) * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bỏ qua'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm vào bữa'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final updated = await ref
            .read(apiClientProvider)
            .addMealItem(localDateString(date), meal.id, addable);
        onUpdate(updated);
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const CustomFoodDialog(),
    );
    if (payload == null) return;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.estimateCustomFood(payload);
      if (!context.mounted) return;
      final saved = await api.createCustomFood(res);
      final addable = saved.isEmpty ? asJsonMap(res['addableItem']) : saved;
      if (addable.isNotEmpty) {
        final updated = await api.addMealItem(
          localDateString(date),
          meal.id,
          addable,
        );
        onUpdate(updated);
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}
