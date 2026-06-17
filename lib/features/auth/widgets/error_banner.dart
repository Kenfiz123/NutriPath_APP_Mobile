import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.red, fontSize: 13),
      ),
    );
  }
}
