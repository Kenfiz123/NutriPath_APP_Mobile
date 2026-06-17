import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/calculator_result_card.dart';

class FullCalculatorScreen extends ConsumerStatefulWidget {
  const FullCalculatorScreen({super.key});

  @override
  ConsumerState<FullCalculatorScreen> createState() =>
      _FullCalculatorScreenState();
}

class _FullCalculatorScreenState extends ConsumerState<FullCalculatorScreen> {
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '170');
  final _duration = TextEditingController(text: '30');
  String _gender = 'female';
  String _activity = 'light';
  String _goal = 'maintain';
  String _exerciseType = 'walking';
  CalorieCalculation? _result;
  bool _saving = false;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return NutriPage(
      children: [
        const SectionHeader(
          title: 'Tính toán chỉ số',
          subtitle: 'BMR, TDEE, macro và mục tiêu dinh dưỡng cá nhân.',
        ),
        NutriCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _field(_age, 'Tuổi')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_weight, 'Kg')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_height, 'Cm')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                ],
                onChanged: (value) =>
                    setState(() => _gender = value ?? _gender),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration: const InputDecoration(labelText: 'Mức vận động'),
                items: const [
                  DropdownMenuItem(
                    value: 'sedentary',
                    child: Text('Ít vận động'),
                  ),
                  DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                  DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                  DropdownMenuItem(value: 'active', child: Text('Nhiều')),
                ],
                onChanged: (value) =>
                    setState(() => _activity = value ?? _activity),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                decoration: const InputDecoration(labelText: 'Mục tiêu'),
                items: const [
                  DropdownMenuItem(value: 'lose', child: Text('Giảm cân')),
                  DropdownMenuItem(value: 'maintain', child: Text('Duy trì')),
                  DropdownMenuItem(
                    value: 'gain',
                    child: Text('Tăng cơ/tăng cân'),
                  ),
                ],
                onChanged: (value) => setState(() => _goal = value ?? _goal),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _exerciseType,
                      decoration: const InputDecoration(labelText: 'Bài tập'),
                      items: const [
                        DropdownMenuItem(
                          value: 'walking',
                          child: Text('Đi bộ'),
                        ),
                        DropdownMenuItem(value: 'running', child: Text('Chạy')),
                        DropdownMenuItem(
                          value: 'cycling',
                          child: Text('Đạp xe'),
                        ),
                        DropdownMenuItem(value: 'gym', child: Text('Gym')),
                        DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                      ],
                      onChanged: (value) => setState(
                        () => _exerciseType = value ?? _exerciseType,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_duration, 'Phút tập')),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _calculate,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: const Text('Tính ngay'),
              ),
            ],
          ),
        ),
        if (_result != null) CalculatorResultCard(result: _result!),
        if (_result != null && session.isLoggedIn)
          FilledButton.tonalIcon(
            onPressed: () => _saveProfile(context),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu làm hồ sơ dinh dưỡng'),
          ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _calculate() async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(apiClientProvider).calculateCalories({
        'age': int.tryParse(_age.text.trim()) ?? 25,
        'weightKg': double.tryParse(_weight.text.trim()) ?? 65,
        'heightCm': double.tryParse(_height.text.trim()) ?? 170,
        'gender': _gender,
        'activityLevel': _activity,
        'goal': _goal,
        'exerciseType': _exerciseType,
        'durationMinutes': int.tryParse(_duration.text.trim()) ?? 30,
      });
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    final result = _result;
    if (result == null) return;
    try {
      final updated = await ref.read(apiClientProvider).saveNutritionProfile({
        ...result.input,
        'activityLevel': _activity,
        'goal': _goal,
      });
      await ref.read(sessionControllerProvider).syncMember(updated);
      if (context.mounted) showSnack(context, 'Đã lưu hồ sơ dinh dưỡng.');
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}
