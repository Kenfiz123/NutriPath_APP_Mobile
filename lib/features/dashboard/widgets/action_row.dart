import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../chat/widgets/chat_sheet.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionButton(
            label: 'Quét ảnh',
            icon: Icons.camera_alt,
            onPressed: () => context.go(AppRoutes.tracker),
            primary: true,
          ),
          ActionButton(
            label: 'Tính calo',
            icon: Icons.calculate,
            onPressed: () => context.go(AppRoutes.calculator),
          ),
          ActionButton(
            label: 'Báo cáo',
            icon: Icons.analytics,
            onPressed: () => context.go(AppRoutes.reports),
          ),
          ActionButton(
            label: 'Chat AI',
            icon: Icons.forum,
            onPressed: () => showChatSheet(context),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: primary ? theme.colorScheme.primary : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary ? Colors.transparent : theme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? Colors.white : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primary ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
