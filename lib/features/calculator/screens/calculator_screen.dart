import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});
  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '170');
  String _gender = 'female';
  final String _activity = 'light';
  final String _goal = 'maintain';
  CalorieCalculation? _res;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NutriPage(
      children: [
        const SectionHeader(
          title: 'Tính toán chỉ số',
          subtitle: 'BMR, TDEE và nhu cầu dinh dưỡng.',
        ),
        NutriCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _f(_age, 'Tuổi')),
                  const SizedBox(width: 8),
                  Expanded(child: _f(_weight, 'Kg')),
                  const SizedBox(width: 8),
                  Expanded(child: _f(_height, 'Cm')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
                decoration: const InputDecoration(labelText: 'Giới tính'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final r = await ref
                      .read(apiClientProvider)
                      .calculateCalories({
                        'age': int.parse(_age.text),
                        'weightKg': double.parse(_weight.text),
                        'heightCm': double.parse(_height.text),
                        'gender': _gender,
                        'activityLevel': _activity,
                        'goal': _goal,
                      });
                  setState(() => _res = r);
                },
                child: const Text('Tính ngay'),
              ),
            ],
          ),
        ),
        if (_res != null)
          NutriCard(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Kết quả ước tính'),
                const SizedBox(height: 16),
                _resLine('BMR', '${_res!.results['bmr']} kcal'),
                _resLine('TDEE', '${_res!.results['tdee']} kcal'),
                _resLine(
                  'Mục tiêu hàng ngày',
                  '${_res!.results['calorieGoal']} kcal',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _f(TextEditingController c, String l) => TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: l),
      );
  Widget _resLine(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
