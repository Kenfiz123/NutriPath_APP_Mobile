import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.from, super.key});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _formError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(sessionControllerProvider).clearError();
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(sessionControllerProvider)
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      context.go(widget.from ?? AppRoutes.dashboard);
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException && error.code == 'unverified') {
        final email = error.payload?['email']?.toString() ?? _email.text.trim();
        context.go('${AppRoutes.verifyOtp}?email=${Uri.encodeComponent(email)}');
      } else {
        setState(() => _formError = readableError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_formError != null) ...[
              ErrorBanner(message: _formError!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: AppStrings.emailLabel,
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => v!.isEmpty ? AppStrings.errorEmptyFields : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: AppStrings.passwordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) => v!.isEmpty ? AppStrings.errorEmptyFields : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: session.busy ? null : _submit,
              child: session.busy
                  ? const CircularProgressIndicator()
                  : const Text(AppStrings.loginButton),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text(AppStrings.noAccountText),
            ),
          ],
        ),
      ),
    );
  }
}
