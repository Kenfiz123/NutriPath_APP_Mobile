import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '168');
  final _formKey = GlobalKey<FormState>();
  String? _formError;
  String _gender = 'female';
  String _activity = 'light';
  final String _goal = 'maintain';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'gender': _gender,
      'age': int.tryParse(_age.text) ?? 25,
      'weightKg': double.tryParse(_weight.text) ?? 65.0,
      'heightCm': double.tryParse(_height.text) ?? 168.0,
      'activityLevel': _activity,
      'goal': _goal,
    };
    try {
      final result = await ref.read(sessionControllerProvider).register(payload);
      if (!mounted) return;
      if (result.unverifiedEmail != null) {
        context.go('${AppRoutes.verifyOtp}?email=${Uri.encodeComponent(result.unverifiedEmail!)}');
      } else {
        context.go(AppRoutes.dashboard);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return AuthScaffold(
      title: AppStrings.registerTitle,
      subtitle: AppStrings.registerSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_formError != null) ...[
              ErrorBanner(message: _formError!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: AppStrings.fullNameLabel,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: AppStrings.emailLabel,
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: AppStrings.passwordLabel,
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _numField(_age, 'Tuổi')),
                const SizedBox(width: 8),
                Expanded(child: _numField(_weight, 'Cân nặng (kg)')),
                const SizedBox(width: 8),
                Expanded(child: _numField(_height, 'Chiều cao (cm)')),
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
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: const InputDecoration(labelText: 'Mức vận động'),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Ít')),
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'active', child: Text('Nhiều')),
              ],
              onChanged: (v) => setState(() => _activity = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: session.busy ? null : _submit,
              child: const Text(AppStrings.registerButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}
