import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/profile_edit_sheet.dart';

class FullProfileScreen extends ConsumerStatefulWidget {
  const FullProfileScreen({super.key});

  @override
  ConsumerState<FullProfileScreen> createState() => _FullProfileScreenState();
}

class _FullProfileScreenState extends ConsumerState<FullProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();
    final asyncBundle = ref.watch(profileBundleProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileBundleProvider);
      },
      child: asyncBundle.when(
        loading: () => const LoadingPanel(),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.invalidate(profileBundleProvider),
            ),
          ],
        ),
        data: (bundle) {
          final profile = bundle.profile;
          final plan = asJsonMap(profile['plan']);
          final benefits = jsonMapList(profile['benefits']);
          final notifications = bundle.notifications;
          final payments = bundle.payments;

          return NutriPage(
            children: [
              NutriCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        member.initials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      member.email,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TierChip(tier: member.tier),
                        Chip(label: Text('${member.calorieTarget} kcal/ngày')),
                        Chip(label: Text('${member.waterTargetGlasses} ly nước')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _editProfile(context, member),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Chỉnh hồ sơ'),
                    ),
                  ],
                ),
              ),
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Gói hiện tại',
                      action: TextButton(
                        onPressed: () => context.go(AppRoutes.pricing),
                        child: const Text('Nâng cấp'),
                      ),
                    ),
                    KeyValueLine(
                      label: 'Tên gói',
                      value: asString(plan['name'], member.tier.toUpperCase()),
                    ),
                    KeyValueLine(
                      label: 'Trạng thái',
                      value: member.subscription?.status ?? 'active',
                    ),
                    KeyValueLine(
                      label: 'Gia hạn',
                      value: member.subscription?.renewsAt ?? '-',
                    ),
                    const SizedBox(height: 8),
                    for (final benefit in benefits.take(5))
                      Row(
                        children: [
                          Icon(
                            asBool(benefit['included'])
                                ? Icons.check_circle
                                : Icons.remove_circle_outline,
                            color: asBool(benefit['included'])
                                ? AppColors.emerald
                                : AppColors.muted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(asString(benefit['label']))),
                        ],
                      ),
                  ],
                ),
              ),
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Thông báo',
                      action: TextButton(
                        onPressed: () async {
                          await ref
                              .read(apiClientProvider)
                              .markAllNotificationsRead();
                          ref.invalidate(profileBundleProvider);
                        },
                        child: const Text('Đã đọc'),
                      ),
                    ),
                    if (notifications.isEmpty)
                      const Text('Chưa có thông báo.')
                    else
                      for (final item in notifications)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.readAt == null
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: item.readAt == null
                                ? AppColors.amber
                                : AppColors.muted,
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            item.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: item.readAt == null
                              ? () async {
                                  await ref
                                      .read(apiClientProvider)
                                      .markNotificationRead(item.id);
                                  ref.invalidate(profileBundleProvider);
                                }
                              : null,
                        ),
                  ],
                ),
              ),
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Lịch sử thanh toán'),
                    if (payments.isEmpty)
                      const Text('Chưa có giao dịch.')
                    else
                      for (final payment in payments.take(6))
                        KeyValueLine(
                          label:
                              '${payment.invoice} • ${payment.planId.toUpperCase()}',
                          value: formatVnd(payment.amount),
                          icon: Icons.receipt_long,
                        ),
                  ],
                ),
              ),
              NutriCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.people_outline, color: AppColors.primary),
                  title: const Text('Bạn bè & Tìm kiếm'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.friends),
                ),
              ),
              NutriCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.red),
                  title: const Text('Đăng xuất'),
                  onTap: () async {
                    await ref.read(sessionControllerProvider).logout();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, Member member) async {
    final payload = await showModalBottomSheet<JsonMap>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProfileEditSheet(member: member),
    );
    if (payload == null) return;
    try {
      final updated = await ref
          .read(apiClientProvider)
          .updateMemberProfile(payload);
      await ref.read(sessionControllerProvider).syncMember(updated);
      ref.invalidate(profileBundleProvider);
      if (context.mounted) showSnack(context, 'Đã cập nhật hồ sơ.');
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}
