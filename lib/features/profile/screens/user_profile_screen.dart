import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(publicProfileProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ người dùng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.friends);
            }
          },
        ),
      ),
      body: asyncProfile.when(
        loading: () => const LoadingPanel(),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.invalidate(publicProfileProvider(widget.userId)),
            )
          ],
        ),
        data: (profile) {
          return Stack(
            children: [
              NutriPage(
                children: [
                  NutriCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            profile.initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          profile.email,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TierChip(tier: profile.tier),
                            Chip(label: Text('${profile.calorieTarget} kcal/ngày')),
                            Chip(label: Text('${profile.waterTargetGlasses} ly nước')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  NutriCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Mục tiêu sức khỏe'),
                        KeyValueLine(
                          label: 'Mục tiêu chính',
                          value: _translateGoal(profile.goal),
                          icon: Icons.track_changes,
                        ),
                        KeyValueLine(
                          label: 'Giới tính',
                          value: _translateGender(profile.gender),
                          icon: Icons.person_outline,
                        ),
                        KeyValueLine(
                          label: 'Tuổi',
                          value: '${profile.age} tuổi',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFriendActionButton(profile),
                ],
              ),
              if (_busy)
                Positioned.fill(
                  child: Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendActionButton(PublicProfile profile) {
    switch (profile.friendshipStatus) {
      case 'friends':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: _busy ? null : () => _removeFriend(profile.id),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.red,
              backgroundColor: AppColors.red.withValues(alpha: 0.1),
            ),
            child: const Text('Hủy kết bạn'),
          ),
        );
      case 'pending_sent':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _removeFriend(profile.id),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Hủy yêu cầu kết bạn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
            ),
          ),
        );
      case 'pending_received':
        return Column(
          children: [
            const Text(
              'Người này đã gửi lời mời kết bạn cho bạn:',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _respondRequest(profile.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _respondRequest(profile.id, true),
                    child: const Text('Chấp nhận'),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _sendRequest(profile.id),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Thêm bạn bè'),
          ),
        );
    }
  }

  String _translateGoal(String goal) {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      case 'maintain':
        return 'Duy trì vóc dáng';
      default:
        return goal;
    }
  }

  String _translateGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'other':
        return 'Khác';
      default:
        return 'Bảo mật';
    }
  }

  Future<void> _sendRequest(String friendId) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).sendFriendRequest(friendId);
      ref.invalidate(publicProfileProvider(widget.userId));
      ref.invalidate(friendRequestsProvider);
      if (mounted) showSnack(context, 'Đã gửi yêu cầu kết bạn.');
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respondRequest(String friendId, bool accept) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).respondFriendRequest(friendId, accept);
      ref.invalidate(publicProfileProvider(widget.userId));
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendsListProvider);
      if (mounted) {
        showSnack(
          context,
          accept ? 'Đã đồng ý kết bạn.' : 'Đã từ chối lời mời.',
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFriend(String friendId) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).removeFriend(friendId);
      ref.invalidate(publicProfileProvider(widget.userId));
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendsListProvider);
      if (mounted) showSnack(context, 'Đã hủy kết bạn / hủy lời mời.');
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
