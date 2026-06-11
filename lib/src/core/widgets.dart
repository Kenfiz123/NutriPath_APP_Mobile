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
    return 'Không kết nối được backend. Hãy kiểm tra server hoặc kết nối mạng của bạn.';
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
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
}

Color mealColor(String id) {
  return switch (id) {
    'breakfast' => NutriColors.amber,
    'lunch' => NutriColors.emerald,
    'dinner' => NutriColors.blue,
    'snack' => NutriColors.purple,
    _ => NutriColors.teal,
  };
}

class NutriPage extends StatelessWidget {
  const NutriPage({
    required this.children,
    this.padding = const EdgeInsets.all(NutriSpacing.page),
    this.bottomPadding = 110,
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
  const NutriCard({
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(NutriSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NutriSpacing.radius),
        child: content,
      );
    }

    return Card(
      color: color,
      child: content,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...action == null ? const <Widget>[] : [action!],
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: NutriSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NutriSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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
    this.height = 10,
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
        backgroundColor: color.withValues(alpha: 0.1),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            normalized == 'svip' ? Icons.workspace_premium : Icons.verified_user,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            normalized.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
      ).colorScheme.errorContainer.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: NutriSpacing.md),
          Text(
            'Đã xảy ra lỗi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: NutriSpacing.xs),
          Text(
            readableError(error),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: NutriSpacing.lg),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại ngay'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NutriSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: NutriSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: NutriSpacing.xl),
              action!,
            ],
          ],
        ),
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
              'Đăng nhập để đồng bộ dashboard, bữa ăn, báo cáo và hội viên của bạn trên mọi thiết bị.',
          icon: Icons.lock_person_outlined,
          action: FilledButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Đăng nhập ngay'),
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
      color: NutriColors.amber.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NutriColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.workspace_premium, color: NutriColors.amber, size: 20),
          ),
          const SizedBox(width: NutriSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: NutriColors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
  const LoadingPanel({this.message = 'Đang tải dữ liệu...', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NutriCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: NutriSpacing.lg),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: NutriSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
