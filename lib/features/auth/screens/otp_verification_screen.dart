import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otp = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  String? _infoMessage;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otp.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _infoMessage = null;
    });

    try {
      await ref
          .read(sessionControllerProvider)
          .verifyOtp(widget.email, _otp.text.trim());
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = readableError(e));
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    setState(() {
      _error = null;
      _infoMessage = null;
    });

    try {
      await ref.read(apiClientProvider).resendOtp(widget.email);
      _startCountdown();
      if (!mounted) return;
      setState(() => _infoMessage = 'Mã OTP mới đã được gửi thành công.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    return AuthScaffold(
      title: 'Xác thực OTP',
      subtitle: 'Nhập mã OTP 6 chữ số đã được gửi tới email:\n${widget.email}',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            if (_infoMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  _infoMessage!,
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _otp,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                labelText: 'Mã xác thực',
                counterText: '',
                prefixIcon: Icon(Icons.security_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mã OTP';
                if (v.trim().length != 6) return 'Mã OTP phải có đúng 6 chữ số';
                if (int.tryParse(v.trim()) == null) {
                  return 'Mã OTP chỉ chứa các chữ số';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: session.busy ? null : _submit,
              child: session.busy
                  ? const CircularProgressIndicator()
                  : const Text('Xác nhận kích hoạt'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _countdown > 0 ? null : _resend,
              child: Text(
                _countdown > 0
                    ? 'Gửi lại mã OTP ($_countdown giây)'
                    : 'Gửi lại mã OTP',
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Quay lại Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}