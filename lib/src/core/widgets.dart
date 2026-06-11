import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
final _number = NumberFormat.decimalPattern('vi_VN');
final _date = DateFormat('yyyy-MM-dd');
final _friendlyDate = DateFormat('dd/MM/yyyy', 'vi_VN');

String localDateString([DateTime? date]) =>
    _date.format(date ?? DateTime.now());

String friendlyDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return _friendlyDate.format(parsed);
}

String formatNumber(num value, {int digits = 0}) {
  final fixed = digits == 0 ? value.round() : value;
  return _number.format(fixed);
}

String formatVnd(num value) => _vnd.format(value);

String readableError(Object error) {
  final text = error.toString();
  final normalized = text.startsWith('Exception: ') ? text.substring(11) : text;
  final lower = normalized.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('connection refused') ||
      lower.contains('xmlhttprequest error')) {
    return 'Không kết nối được backend. Hãy kiểm tra server đang chạy ở port 8080 rồi thử lại.';
  }
  if (lower.contains('formatexception')) {
    return 'Backend trả về dữ liệu không hợp lệ. Hãy kiểm tra log server.';
  }
  if (normalized.trim().isEmpty) {
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
  return normalized;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Color mealColor(String id) {
  return switch (id) {
    'breakfast' => NutriColors.amber,
    'lunch' => NutriColors.primary,
    'dinner' => NutriColors.blue,
    'snack' => NutriColors.purple,
    _ => NutriColors.teal,
  };
}

class NutriPage extends StatelessWidget {
  const NutriPage({
    required this.children,
    this.padding = const EdgeInsets.all(NutriSpacing.page),
    this.bottomPadding = 96,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding.copyWith(bottom: bottomPadding),
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) =>
          const SizedBox(height: NutriSpacing.md),
      itemCount: children.length,
    );
  }
}

class NutriCard extends StatelessWidget {
  const NutriCard({required this.child, this.padding, this.color, super.key});

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(NutriSpacing.lg),
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...action == null ? const <Widget>[] : [action!],
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = NutriColors.primary,
    this.caption,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NutriCard(
      padding: const EdgeInsets.all(NutriSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: NutriSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({
    required this.value,
    this.color = NutriColors.primary,
    this.height = 9,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        minHeight: height,
        value: clamped,
        backgroundColor: color.withValues(alpha: 0.14),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class TierChip extends StatelessWidget {
  const TierChip({required this.tier, super.key});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final normalized = tier.toLowerCase();
    final color = switch (normalized) {
      'svip' => NutriColors.amber,
      'vip' => NutriColors.emerald,
      _ => NutriColors.blue,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        normalized == 'svip' ? Icons.workspace_premium : Icons.verified_user,
        size: 16,
        color: color,
      ),
      label: Text(normalized.toUpperCase()),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.34)),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: NutriSpacing.sm),
              Expanded(
                child: Text(
                  readableError(error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: NutriSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NutriCard(
      child: Column(
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: NutriSpacing.sm),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: NutriSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return NutriPage(
      children: [
        EmptyState(
          title: 'Bạn cần đăng nhập',
          message:
              'Đăng nhập để đồng bộ dashboard, bữa ăn, báo cáo và hội viên.',
          icon: Icons.lock_outline,
          action: FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: const Text('Đăng nhập'),
          ),
        ),
      ],
    );
  }
}

class LockedPanel extends StatelessWidget {
  const LockedPanel({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      color: NutriColors.amber.withValues(alpha: 0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium, color: NutriColors.amber),
          const SizedBox(width: NutriSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/pricing'),
            child: const Text('Nâng cấp'),
          ),
        ],
      ),
    );
  }
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({this.message = 'Đang tải...', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: NutriSpacing.md),
          Text(message),
        ],
      ),
    );
  }
}

class KeyValueLine extends StatelessWidget {
  const KeyValueLine({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: NutriSpacing.sm),
          ],
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
