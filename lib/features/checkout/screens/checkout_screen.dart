import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    required this.initialPlanId,
    required this.initialBilling,
    super.key,
  });
  final String initialPlanId, initialBilling;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    return NutriPage(
      children: [
        const SectionHeader(
          title: 'Thanh toán',
          subtitle: 'Mô phỏng quy trình thanh toán.',
        ),
        NutriCard(
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn đang đăng ký gói',
                style: TextStyle(color: AppColors.muted),
              ),
              Text(
                widget.initialPlanId.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final (_, updated) = await ref
                      .read(apiClientProvider)
                      .createPayment({
                        'planId': widget.initialPlanId,
                        'billing': widget.initialBilling,
                        'paymentMethod': 'demo',
                      });
                  await ref.read(sessionControllerProvider).syncMember(updated);
                  if (context.mounted) context.go(AppRoutes.profile);
                },
                child: const Text('Xác nhận thanh toán (Demo)'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
