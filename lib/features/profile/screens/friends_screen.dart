import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bạn bè'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bạn bè'),
              Tab(text: 'Lời mời'),
              Tab(text: 'Tìm kiếm'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsTab(),
            _buildRequestsTab(),
            _buildSearchTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    final asyncFriends = ref.watch(friendsListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(friendsListProvider);
      },
      child: asyncFriends.when(
        loading: () => _buildScrollableContainer(const LoadingPanel()),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.invalidate(friendsListProvider),
            )
          ],
        ),
        data: (friends) {
          if (friends.isEmpty) {
            return _buildScrollableContainer(
              const EmptyState(
                title: 'Chưa có bạn bè',
                message: 'Hãy sang tab Tìm kiếm để kết nối với người dùng khác!',
                icon: Icons.people_outline,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friend = friends[index];
              return NutriCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      friend.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    friend.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(friend.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TierChip(tier: friend.tier),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                        onPressed: () => context.go('${AppRoutes.friendChat}/${friend.id}'),
                      ),
                    ],
                  ),
                  onTap: () => context.go('${AppRoutes.userProfile}/${friend.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    final asyncRequests = ref.watch(friendRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(friendRequestsProvider);
      },
      child: asyncRequests.when(
        loading: () => _buildScrollableContainer(const LoadingPanel()),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => ref.invalidate(friendRequestsProvider),
            )
          ],
        ),
        data: (requests) {
          final incoming = requests.incoming;
          final outgoing = requests.outgoing;

          if (incoming.isEmpty && outgoing.isEmpty) {
            return _buildScrollableContainer(
              const EmptyState(
                title: 'Không có lời mời nào',
                message: 'Hộp thư yêu cầu kết bạn của bạn hiện đang trống.',
                icon: Icons.mail_outline,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (incoming.isNotEmpty) ...[
                const SectionHeader(title: 'Lời mời đã nhận'),
                const SizedBox(height: 8),
                ...incoming.map((req) => _buildIncomingCard(req)),
                const SizedBox(height: 24),
              ],
              if (outgoing.isNotEmpty) ...[
                const SectionHeader(title: 'Yêu cầu đã gửi'),
                const SizedBox(height: 8),
                ...outgoing.map((req) => _buildOutgoingCard(req)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildIncomingCard(FriendRequest req) {
    return NutriCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  req.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(req.email, style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              TierChip(tier: req.tier),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _respondRequest(req.friendId, false),
                child: const Text('Từ chối', style: TextStyle(color: AppColors.red)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _respondRequest(req.friendId, true),
                child: const Text('Chấp nhận'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingCard(FriendRequest req) {
    return NutriCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.muted.withValues(alpha: 0.1),
            child: Text(
              req.initials,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(req.email, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _cancelRequest(req.friendId),
            child: const Text('Hủy', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final asyncSearch = ref.watch(userSearchProvider(_searchQuery));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Tìm người dùng bằng tên hoặc email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
        ),
        Expanded(
          child: _searchQuery.isEmpty
              ? const Center(
                  child: Text(
                    'Nhập tên hoặc email và nhấn tìm kiếm',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : asyncSearch.when(
                  loading: () => const LoadingPanel(),
                  error: (err, stack) => NutriPage(
                    children: [
                      ErrorPanel(
                        error: err,
                        onRetry: () => ref.invalidate(userSearchProvider(_searchQuery)),
                      )
                    ],
                  ),
                  data: (results) {
                    if (results.isEmpty) {
                      return const EmptyState(
                        title: 'Không tìm thấy người dùng',
                        message: 'Thử tìm kiếm với từ khóa khác.',
                        icon: Icons.search_off,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = results[index];
                        return NutriCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                user.initials,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusBadge(user.friendshipStatus),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: AppColors.muted),
                              ],
                            ),
                            onTap: () => context.go('${AppRoutes.userProfile}/${user.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'friends':
        color = AppColors.emerald;
        text = 'Bạn bè';
        break;
      case 'pending_sent':
        color = AppColors.amber;
        text = 'Đã gửi lời mời';
        break;
      case 'pending_received':
        color = AppColors.blue;
        text = 'Chờ phản hồi';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _respondRequest(String friendId, bool accept) async {
    try {
      await ref.read(apiClientProvider).respondFriendRequest(friendId, accept);
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendsListProvider);
      if (accept && _searchQuery.isNotEmpty) {
        ref.invalidate(userSearchProvider(_searchQuery));
      }
      if (mounted) {
        showSnack(
          context,
          accept ? 'Đã đồng ý kết bạn.' : 'Đã từ chối lời mời.',
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    }
  }

  Future<void> _cancelRequest(String friendId) async {
    try {
      await ref.read(apiClientProvider).removeFriend(friendId);
      ref.invalidate(friendRequestsProvider);
      if (_searchQuery.isNotEmpty) {
        ref.invalidate(userSearchProvider(_searchQuery));
      }
      if (mounted) showSnack(context, 'Đã hủy yêu cầu kết bạn.');
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    }
  }

  Widget _buildScrollableContainer(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 400),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }
}
