import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _codeSent = false;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _infoMessage;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _error = null;
      _infoMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _infoMessage =
            'Nếu email tồn tại, mã xác nhận sẽ được gửi đến hộp thư của bạn.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _error = null;
      _infoMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .resetPassword(
            email: _email.text.trim(),
            code: _code.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      showSnack(context, 'Mật khẩu đã được cập nhật. Đăng nhập lại nhé.');
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = readableError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Quên mật khẩu',
      subtitle: 'Nhập email tài khoản để nhận mã xác nhận đặt lại mật khẩu.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            if (_infoMessage != null) ...[
              _InfoBanner(message: _infoMessage!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              enabled: !_busy && !_codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Vui lòng nhập email';
                final valid = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(email);
                return valid ? null : 'Email không hợp lệ';
              },
            ),
            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                decoration: const InputDecoration(
                  labelText: 'Mã xác nhận',
                  counterText: '',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (code.isEmpty) return 'Vui lòng nhập mã xác nhận';
                  if (code.length != 6) return 'Mã xác nhận gồm 6 chữ số';
                  if (int.tryParse(code) == null) {
                    return 'Mã xác nhận chỉ chứa chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
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
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (password.length < 6) {
                    return 'Mật khẩu cần ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                enabled: !_busy,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) {
                    return 'Vui lòng nhập lại mật khẩu';
                  }
                  if (value != _password.text) {
                    return 'Mật khẩu nhập lại không khớp';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : _codeSent
                  ? _resetPassword
                  : _requestCode,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _codeSent
                          ? Icons.lock_reset_outlined
                          : Icons.mark_email_read_outlined,
                    ),
              label: Text(_codeSent ? 'Đặt lại mật khẩu' : 'Gửi mã xác nhận'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : () => context.go(AppRoutes.login),
              child: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
