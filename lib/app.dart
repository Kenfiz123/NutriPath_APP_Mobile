import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import 'core/app_services.dart';
import 'core/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_sizes.dart';
import 'features/admin/screens/admin_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/calculator/screens/full_calculator_screen.dart';
import 'features/chat/widgets/chat_sheet.dart';
import 'features/checkout/screens/full_checkout_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/meal_tracker/screens/meal_tracker_screen.dart';
import 'features/pricing/screens/full_pricing_screen.dart';
import 'features/profile/screens/full_profile_screen.dart';
import 'features/profile/screens/friends_screen.dart';
import 'features/profile/screens/user_profile_screen.dart';
import 'features/profile/screens/friend_chat_screen.dart';
import 'features/recipes/screens/full_recipes_screen.dart';
import 'features/reports/screens/full_reports_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(sessionControllerProvider);
  const protectedPaths = {
    AppRoutes.dashboard,
    AppRoutes.tracker,
    AppRoutes.reports,
    AppRoutes.profile,
    AppRoutes.checkout,
    AppRoutes.friends,
    AppRoutes.userProfile,
    AppRoutes.friendChat,
  };

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: session,
    redirect: (context, state) {
      if (!session.initialized) return null;
      final path = state.uri.path;
      final isAuthPage =
          path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.verifyOtp;
      if (isAuthPage && session.isLoggedIn) return AppRoutes.dashboard;
      if (protectedPaths.contains(path) && !session.isLoggedIn) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$from';
      }
      if (path == AppRoutes.admin &&
          (!session.isLoggedIn || !session.isAdmin)) {
        return session.isLoggedIn
            ? AppRoutes.dashboard
            : '${AppRoutes.login}?from=%2Fadmin';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.dashboard,
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) => OtpVerificationScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.tracker,
            builder: (context, state) => const MealTrackerScreen(),
          ),
          GoRoute(
            path: AppRoutes.recipes,
            builder: (context, state) => const FullRecipesScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const FullReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const FullProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.calculator,
            builder: (context, state) => const FullCalculatorScreen(),
          ),
          GoRoute(
            path: AppRoutes.pricing,
            builder: (context, state) => const FullPricingScreen(),
          ),
          GoRoute(
            path: AppRoutes.checkout,
            builder: (context, state) => FullCheckoutScreen(
              initialPlanId: state.uri.queryParameters['plan'] ?? 'vip',
              initialBilling: state.uri.queryParameters['billing'] ?? 'monthly',
            ),
          ),
          GoRoute(
            path: AppRoutes.admin,
            builder: (context, state) => const FullAdminScreen(),
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (context, state) => const FriendsScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.userProfile}/:id',
            builder: (context, state) =>
                UserProfileScreen(userId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.friendChat}/:id',
            builder: (context, state) =>
                FriendChatScreen(friendId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

class NutriPathApp extends ConsumerWidget {
  const NutriPathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'NutriPath',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildNutriTheme(Brightness.light),
      darkTheme: buildNutriTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final selectedIndex = _selectedIndex(location);
    final isFriendChat =
        location == AppRoutes.friendChat ||
        location.startsWith('${AppRoutes.friendChat}/');
    final canOpenChat =
        location != AppRoutes.login &&
        location != AppRoutes.register &&
        !isFriendChat;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSizes.sm),
            const Text('NutriPath'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tính calo',
            onPressed: () => context.go(AppRoutes.calculator),
            icon: const Icon(Icons.calculate_outlined),
          ),
          IconButton(
            tooltip: 'Gói thành viên',
            onPressed: () => context.go(AppRoutes.pricing),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
          if (session.isAdmin)
            IconButton(
              tooltip: 'Admin',
              onPressed: () => context.go(AppRoutes.admin),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: 'Đổi theme',
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            icon: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
      body: session.initialized ? child : const _StartupLoading(),
      floatingActionButton: canOpenChat
          ? FloatingActionButton(
              tooltip: 'Chat NutriBot',
              onPressed: () => showChatSheet(context),
              child: const Icon(Icons.chat_bubble_outline),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) => context.go(_destinations[index].path),
        destinations: _destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  int _selectedIndex(String path) {
    final index = _destinations.indexWhere((item) => item.path == path);
    return index;
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination(
    path: AppRoutes.dashboard,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  _Destination(
    path: AppRoutes.tracker,
    label: 'Theo dõi',
    icon: Icons.restaurant_menu_outlined,
    selectedIcon: Icons.restaurant_menu,
  ),
  _Destination(
    path: AppRoutes.recipes,
    label: 'Công thức',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
  ),
  _Destination(
    path: AppRoutes.reports,
    label: 'Báo cáo',
    icon: Icons.insert_chart_outlined,
    selectedIcon: Icons.insert_chart,
  ),
  _Destination(
    path: AppRoutes.profile,
    label: 'Hồ sơ',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];
