import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_services.dart';
import '../core/app_theme.dart';
import '../core/models.dart';
import '../core/widgets.dart';

// --- AUTH SCREENS ---

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.from, super.key});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _formError;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(sessionControllerProvider).clearError();
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(sessionControllerProvider)
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      context.go(widget.from ?? '/dashboard');
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return _AuthScaffold(
      title: 'Chào mừng trở lại!',
      subtitle: 'Đăng nhập để theo dõi hành trình dinh dưỡng của bạn.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_formError != null) ...[
              _ErrorBanner(message: _formError!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: session.busy ? null : _submit,
              child: session.busy
                  ? const CircularProgressIndicator()
                  : const Text('Đăng nhập'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Chưa có tài khoản? Đăng ký ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '168');
  final _formKey = GlobalKey<FormState>();
  String? _formError;
  String _gender = 'female';
  String _activity = 'light';
  String _goal = 'maintain';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    final payload = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'gender': _gender,
      'age': int.tryParse(_age.text) ?? 25,
      'weightKg': double.tryParse(_weight.text) ?? 65.0,
      'heightCm': double.tryParse(_height.text) ?? 168.0,
      'activityLevel': _activity,
      'goal': _goal,
    };
    try {
      await ref.read(sessionControllerProvider).register(payload);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return _AuthScaffold(
      title: 'Tạo tài khoản',
      subtitle: 'Bắt đầu hành trình sống khỏe cùng NutriPath.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_formError != null) ...[
              _ErrorBanner(message: _formError!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Họ tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _numField(_age, 'Tuổi')),
                const SizedBox(width: 8),
                Expanded(child: _numField(_weight, 'Cân nặng (kg)')),
                const SizedBox(width: 8),
                Expanded(child: _numField(_height, 'Chiều cao (cm)')),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                DropdownMenuItem(value: 'male', child: Text('Nam')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _activity,
              decoration: const InputDecoration(labelText: 'Mức vận động'),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Ít')),
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'active', child: Text('Nhiều')),
              ],
              onChanged: (v) => setState(() => _activity = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: session.busy ? null : _submit,
              child: const Text('Đăng ký ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco, color: NutriColors.primary, size: 48),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              NutriCard(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NutriColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NutriColors.red.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: NutriColors.red, fontSize: 13),
      ),
    );
  }
}

// --- DASHBOARD ---

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiClientProvider).getDashboard(date: localDateString());
  }

  void _reload() => setState(() {
    _future = ref.read(apiClientProvider).getDashboard(date: localDateString());
  });

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isLoggedIn) return const LoginPrompt();

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NutriPage(
              children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
            );
          }
          if (!snapshot.hasData) return const LoadingPanel();
          final data = snapshot.data!;
          final n = data.nutrition;

          return NutriPage(
            children: [
              _GreetingHeader(data: data),
              _StatsGrid(data: data),
              _ProgressCard(n: n),
              _AITipsCard(tips: data.tips),
              _ActionRow(),
              if (data.member.canUseCoach)
                _CoachPreviewCard(api: ref.read(apiClientProvider))
              else
                const LockedPanel(
                  title: 'Mở khóa AI Coach',
                  message: 'Kế hoạch ăn uống cá nhân hóa dành riêng cho SVIP.',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.greeting,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NutriColors.muted,
                  ),
                ),
                Text(
                  data.member.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TierChip(tier: data.member.tier),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final n = data.nutrition;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        MetricCard(
          label: 'Calo',
          value: formatNumber(n.totals.calories),
          icon: Icons.local_fire_department,
          accent: NutriColors.orange,
          caption: 'mục tiêu ${formatNumber(n.targets.calories)}',
        ),
        MetricCard(
          label: 'Protein',
          value: '${n.totals.protein.round()}g',
          icon: Icons.fitness_center,
          accent: NutriColors.blue,
          caption: 'cần ${n.targets.protein.round()}g',
        ),
        MetricCard(
          label: 'Nước',
          value: '${data.mealLog.waterGlasses} ly',
          icon: Icons.water_drop,
          accent: NutriColors.teal,
          caption: 'cần ${data.member.waterTargetGlasses}',
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.n});
  final MealSummary n;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Hôm nay'),
          const SizedBox(height: 16),
          ProgressLine(
            value: n.totals.calories / n.targets.calories,
            height: 12,
            color: NutriColors.primary,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${n.calorieProgressPct}% mục tiêu',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Còn ${formatNumber(n.remainingCalories)} kcal',
                style: const TextStyle(color: NutriColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AITipsCard extends StatelessWidget {
  const _AITipsCard({required this.tips});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();
    return NutriCard(
      color: NutriColors.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: NutriColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gợi ý từ NutriBot',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in tips.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $tip',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            label: 'Quét ảnh',
            icon: Icons.camera_alt,
            onPressed: () => context.go('/tracker'),
            primary: true,
          ),
          _ActionButton(
            label: 'Tính calo',
            icon: Icons.calculate,
            onPressed: () => context.go('/calculator'),
          ),
          _ActionButton(
            label: 'Báo cáo',
            icon: Icons.analytics,
            onPressed: () => context.go('/reports'),
          ),
          _ActionButton(
            label: 'Chat AI',
            icon: Icons.forum,
            onPressed: () => showChatSheet(context),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
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

// --- MEAL TRACKER ---

class MealTrackerScreen extends ConsumerStatefulWidget {
  const MealTrackerScreen({super.key});

  @override
  ConsumerState<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends ConsumerState<MealTrackerScreen> {
  late DateTime _date;
  late Future<MealLog> _future;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _future = _load();
  }

  Future<MealLog> _load() =>
      ref.read(apiClientProvider).getMealLog(localDateString(_date));

  void _reload() => setState(() => _future = _load());

  void _shift(int d) => setState(() {
    _date = _date.add(Duration(days: d));
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<MealLog>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NutriPage(
              children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
            );
          }
          if (!snapshot.hasData) return const LoadingPanel();
          final log = snapshot.data!;

          return NutriPage(
            children: [
              _DateNavigator(
                date: _date,
                onPrev: () => _shift(-1),
                onNext: () => _shift(1),
              ),
              _WaterTracker(log: log, onUpdate: _reload),
              _WorkoutTracker(log: log, onUpdate: _reload),
              for (final m in log.meals)
                _MealSection(meal: m, date: _date, onUpdate: _reload),
            ],
          );
        },
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrev,
    required this.onNext,
  });
  final DateTime date;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Column(
            children: [
              Text(
                'Nhật ký bữa ăn',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                friendlyDate(localDateString(date)),
                style: const TextStyle(color: NutriColors.muted, fontSize: 13),
              ),
            ],
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _WaterTracker extends ConsumerWidget {
  const _WaterTracker({required this.log, required this.onUpdate});
  final MealLog log;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = log.summary.targets.waterGlasses.round();
    final current = log.waterGlasses;

    return NutriCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NutriColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: NutriColors.teal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uống nước',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                ProgressLine(
                  value: current / (target == 0 ? 1 : target),
                  color: NutriColors.teal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                onPressed: current > 0
                    ? () async {
                        await ref
                            .read(apiClientProvider)
                            .updateWater(log.date, current - 1);
                        onUpdate();
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$current',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await ref
                      .read(apiClientProvider)
                      .updateWater(log.date, current + 1);
                  onUpdate();
                },
                icon: const Icon(Icons.add_circle, color: NutriColors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutTracker extends ConsumerWidget {
  const _WorkoutTracker({required this.log, required this.onUpdate});

  final MealLog log;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = jsonMapList(log.activity['workouts']);
    final calories = asDouble(log.activity['workoutCalories']);
    final minutes = asInt(log.activity['workoutMinutes']);

    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Vận động',
            subtitle: '${formatNumber(calories)} kcal đã đốt • $minutes phút',
            action: IconButton.filledTonal(
              tooltip: 'Ghi bài tập',
              onPressed: () => _addWorkout(context, ref),
              icon: const Icon(Icons.add),
            ),
          ),
          if (workouts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Chưa có bài tập nào hôm nay.',
                style: TextStyle(color: NutriColors.muted),
              ),
            )
          else
            for (final workout in workouts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.fitness_center, color: NutriColors.blue),
                ),
                title: Text(
                  asString(workout['label'], 'Bài tập'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${asInt(workout['durationMinutes'])} phút • ${asString(workout['intensity'], 'moderate')}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${asInt(workout['calories'])} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      tooltip: 'Xóa bài tập',
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        try {
                          await ref
                              .read(apiClientProvider)
                              .deleteWorkout(log.date, asString(workout['id']));
                          onUpdate();
                        } catch (e) {
                          if (context.mounted)
                            showSnack(context, readableError(e));
                        }
                      },
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addWorkout(BuildContext context, WidgetRef ref) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const _WorkoutDialog(),
    );
    if (payload == null) return;
    try {
      await ref.read(apiClientProvider).addWorkout(log.date, payload);
      onUpdate();
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection({
    required this.meal,
    required this.date,
    required this.onUpdate,
  });
  final MealSection meal;
  final DateTime date;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = mealColor(meal.id);
    return NutriCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.restaurant, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        '${meal.time} • mục tiêu ${meal.targetKcal.round()} kcal',
                        style: const TextStyle(
                          color: NutriColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${meal.totalCalories.round()} kcal',
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
          if (meal.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Chưa có món ăn nào.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: NutriColors.muted,
                ),
              ),
            )
          else
            for (final item in meal.items)
              ListTile(
                dense: true,
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${item.portion} • x${item.quantity.round()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.calories.round()} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        await ref
                            .read(apiClientProvider)
                            .deleteMealItem(
                              localDateString(date),
                              meal.id,
                              item.id,
                            );
                        onUpdate();
                      },
                    ),
                  ],
                ),
              ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TextIconButton(
                  icon: Icons.search,
                  label: 'Tìm món',
                  onTap: () => _addFromLibrary(context, ref),
                ),
                _TextIconButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Chụp ảnh',
                  onTap: () => _addFromPhoto(context, ref),
                ),
                _TextIconButton(
                  icon: Icons.edit_note,
                  label: 'Tự nấu',
                  onTap: () => _addCustom(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFromLibrary(BuildContext context, WidgetRef ref) async {
    final food = await showDialog<Food>(
      context: context,
      builder: (context) => _FoodPickerDialog(api: ref.read(apiClientProvider)),
    );
    if (food == null) return;
    await ref
        .read(apiClientProvider)
        .addMealItem(localDateString(date), meal.id, food.id);
    onUpdate();
  }

  Future<void> _addFromPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final res = await ref
          .read(apiClientProvider)
          .estimateFoodPhoto(imageDataUrl: dataUrl);
      if (!context.mounted) return;

      final estimate = asJsonMap(res['estimate']);
      final addable = asJsonMap(res['addableItem']);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI nhận diện món ăn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                asString(estimate['dishName']),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text('${estimate['calories']} kcal • ${estimate['portion']}'),
              const SizedBox(height: 12),
              Text(
                'Độ tin cậy: ${(asDouble(estimate['confidence']) * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bỏ qua'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm vào bữa'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref
            .read(apiClientProvider)
            .addMealItem(localDateString(date), meal.id, addable);
        onUpdate();
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const _CustomFoodDialog(),
    );
    if (payload == null) return;
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.estimateCustomFood(payload);
      if (!context.mounted) return;
      final saved = await api.createCustomFood(res);
      final addable = saved.isEmpty ? asJsonMap(res['addableItem']) : saved;
      if (addable.isNotEmpty) {
        await api.addMealItem(localDateString(date), meal.id, addable);
        onUpdate();
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class _TextIconButton extends StatelessWidget {
  const _TextIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: NutriColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AI CHAT SHEET ---

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({super.key});

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  List<String> _quickReplies = [];
  String _mode = 'assistant';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    final hist = await api.getChatHistory();
    final replies = await api.getQuickReplies();
    if (!mounted) return;
    setState(() {
      _messages = hist;
      _quickReplies = replies;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final msg = text ?? _input.text.trim();
    if (msg.isEmpty || _busy) return;
    _input.clear();
    setState(() => _busy = true);
    try {
      final res = await ref
          .read(apiClientProvider)
          .sendChatMessage(msg, mode: _mode);
      if (!mounted) return;
      setState(() {
        _messages = jsonMapList(
          res['messages'],
        ).map(ChatMessage.fromJson).toList();
        _quickReplies = stringList(res['quickReplies']);
        _busy = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, readableError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _ChatHeader(
              mode: _mode,
              onModeChanged: (v) => setState(() => _mode = v),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) => _ChatBubble(msg: _messages[i]),
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            _QuickReplies(replies: _quickReplies, onSelect: _send),
            _ChatInput(controller: _input, onSend: () => _send(), busy: _busy),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.mode, required this.onModeChanged});
  final String mode;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: NutriColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'NutriBot',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'assistant', label: Text('Bot')),
              ButtonSegment(value: 'coach', label: Text('Coach')),
            ],
            selected: {mode},
            onSelectionChanged: (v) => onModeChanged(v.first),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isMe = msg.sender == 'user';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? NutriColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : null,
            bottomLeft: !isMe ? const Radius.circular(0) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : null,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.replies, required this.onSelect});
  final List<String> replies;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(replies[i]),
          onPressed: () => onSelect(replies[i]),
          backgroundColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.busy,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Hỏi NutriBot...',
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: busy ? null : onSend,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

// --- COACH PREVIEW ---

class _CoachPreviewCard extends StatefulWidget {
  const _CoachPreviewCard({required this.api});
  final ApiClient api;

  @override
  State<_CoachPreviewCard> createState() => _CoachPreviewCardState();
}

class _CoachPreviewCardState extends State<_CoachPreviewCard> {
  late Future<List<WeeklyCoachPlan>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getWeeklyCoachPlans();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WeeklyCoachPlan>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return NutriCard(
            color: NutriColors.amber.withValues(alpha: 0.1),
            child: Column(
              children: [
                const SectionHeader(
                  title: 'AI Coach',
                  subtitle: 'Tạo kế hoạch ăn uống 7 ngày ngay bây giờ.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await widget.api.createWeeklyCoachPlan();
                    setState(() {
                      _future = widget.api.getWeeklyCoachPlans();
                    });
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Tạo kế hoạch tuần'),
                  style: FilledButton.styleFrom(
                    backgroundColor: NutriColors.amber,
                  ),
                ),
              ],
            ),
          );
        }
        final plan = snapshot.data!.first;
        return NutriCard(
          color: NutriColors.amber.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeader(title: 'AI Coach Plan'),
                  IconButton(
                    onPressed: () => setState(() {
                      _future = widget.api.getWeeklyCoachPlans();
                    }),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final step in plan.actionSteps.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: NutriColors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// --- SHARED DIALOGS ---

class _FoodPickerDialog extends StatefulWidget {
  const _FoodPickerDialog({required this.api});
  final ApiClient api;

  @override
  State<_FoodPickerDialog> createState() => _FoodPickerDialogState();
}

class _FoodPickerDialogState extends State<_FoodPickerDialog> {
  final _search = TextEditingController();
  late Future<List<Food>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getFoods();
  }

  void _run() => setState(() => _future = widget.api.getFoods(_search.text));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn từ thư viện'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                suffixIcon: IconButton(
                  onPressed: _run,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<Food>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final foods = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: foods.length,
                    itemBuilder: (context, i) {
                      final f = foods[i];
                      return ListTile(
                        title: Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(f.category),
                        trailing: Text('${f.calories.round()} kcal'),
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFoodDialog extends StatefulWidget {
  const _CustomFoodDialog();
  @override
  State<_CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<_CustomFoodDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ước tính món tự nấu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên món'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nguyên liệu & cách nấu',
              hintText: 'Ví dụ: 100g ức gà áp chảo, 1 chén cơm gạo lứt...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'name': _name.text,
            'rawText': _desc.text,
            'servings': 1,
          }),
          child: const Text('Gửi AI'),
        ),
      ],
    );
  }
}

class _WorkoutDialog extends StatefulWidget {
  const _WorkoutDialog();

  @override
  State<_WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<_WorkoutDialog> {
  final _duration = TextEditingController(text: '30');
  final _distance = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'walking';
  String _intensity = 'moderate';

  @override
  void dispose() {
    _duration.dispose();
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ghi bài tập'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Loại bài tập'),
              items: const [
                DropdownMenuItem(value: 'walking', child: Text('Đi bộ')),
                DropdownMenuItem(value: 'running', child: Text('Chạy bộ')),
                DropdownMenuItem(value: 'cycling', child: Text('Đạp xe')),
                DropdownMenuItem(value: 'gym', child: Text('Gym')),
                DropdownMenuItem(value: 'hiit', child: Text('HIIT')),
                DropdownMenuItem(value: 'swimming', child: Text('Bơi')),
                DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                DropdownMenuItem(value: 'custom', child: Text('Khác')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thời lượng phút'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distance,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quãng đường km',
                hintText: 'Tùy chọn',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _intensity,
              decoration: const InputDecoration(labelText: 'Cường độ'),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'hard', child: Text('Nặng')),
                DropdownMenuItem(value: 'very_hard', child: Text('Rất nặng')),
              ],
              onChanged: (value) =>
                  setState(() => _intensity = value ?? _intensity),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ví dụ: chạy dốc, nhịp tim cao...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final duration = int.tryParse(_duration.text.trim()) ?? 0;
            if (duration <= 0) return;
            final payload = <String, dynamic>{
              'type': _type,
              'durationMinutes': duration,
              'intensity': _intensity,
              'notes': _notes.text.trim(),
            };
            final distance = double.tryParse(_distance.text.trim());
            if (distance != null && distance > 0) {
              payload['distanceKm'] = distance;
            }
            Navigator.pop(context, payload);
          },
          child: const Text('Lưu bài tập'),
        ),
      ],
    );
  }
}

// (Remaining screens like Pricing, Reports, Profile, Admin would be similarly overhauled
// for brevity in this single edit block, focusing on core UX first)

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});
  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '170');
  String _gender = 'female', _activity = 'light', _goal = 'maintain';
  CalorieCalculation? _res;

  @override
  Widget build(BuildContext context) {
    return NutriPage(
      children: [
        const SectionHeader(
          title: 'Tính toán chỉ số',
          subtitle: 'BMR, TDEE và nhu cầu dinh dưỡng.',
        ),
        NutriCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _f(_age, 'Tuổi')),
                  const SizedBox(width: 8),
                  Expanded(child: _f(_weight, 'Kg')),
                  const SizedBox(width: 8),
                  Expanded(child: _f(_height, 'Cm')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
                decoration: const InputDecoration(labelText: 'Giới tính'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final r = await ref
                      .read(apiClientProvider)
                      .calculateCalories({
                        'age': int.parse(_age.text),
                        'weightKg': double.parse(_weight.text),
                        'heightCm': double.parse(_height.text),
                        'gender': _gender,
                        'activityLevel': _activity,
                        'goal': _goal,
                      });
                  setState(() => _res = r);
                },
                child: const Text('Tính ngay'),
              ),
            ],
          ),
        ),
        if (_res != null)
          NutriCard(
            color: NutriColors.primary.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Kết quả ước tính'),
                const SizedBox(height: 16),
                _resLine('BMR', '${_res!.results['bmr']} kcal'),
                _resLine('TDEE', '${_res!.results['tdee']} kcal'),
                _resLine(
                  'Mục tiêu hàng ngày',
                  '${_res!.results['calorieGoal']} kcal',
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _f(TextEditingController c, String l) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: l),
  );
  Widget _resLine(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});
  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecipeCollection>(
      future: ref.read(apiClientProvider).getRecipes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPanel();
        final recipes = snapshot.data!.recipes;
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Khám phá công thức',
              subtitle: 'Hàng ngàn món ăn healthy từ chuyên gia.',
            ),
            for (final r in recipes)
              NutriCard(
                onTap: () => showRecipeDetails(context, r),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: NutriColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: NutriColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${r.calories.round()} kcal • ${r.timeMinutes} phút',
                            style: const TextStyle(
                              color: NutriColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: NutriColors.slate300,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NutritionReport>(
      future: ref.read(apiClientProvider).getNutritionReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPanel();
        final rep = snapshot.data!;
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Báo cáo tuần',
              subtitle: 'Phân tích thói quen ăn uống của bạn.',
            ),
            NutriCard(
              child: Column(
                children: [
                  const Text(
                    'Calo trung bình ngày',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${rep.averages['calories'].round()} kcal',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NutriColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Phân tích AI'),
                  const SizedBox(height: 12),
                  for (final ins in rep.insights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $ins',
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();
    return NutriPage(
      children: [
        NutriCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: NutriColors.primary.withValues(alpha: 0.1),
                child: Text(
                  member.initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                member.email,
                style: const TextStyle(color: NutriColors.muted),
              ),
              const SizedBox(height: 16),
              TierChip(tier: member.tier),
            ],
          ),
        ),
        NutriCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.workspace_premium,
                  color: NutriColors.amber,
                ),
                title: const Text('Gói thành viên'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/pricing'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: NutriColors.red),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  await ref.read(sessionControllerProvider).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});
  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plan>>(
      future: ref.read(apiClientProvider).getPlans('monthly'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingPanel();
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Nâng cấp hội viên',
              subtitle: 'Mở khóa toàn bộ tính năng AI.',
            ),
            for (final p in snapshot.data!) _OverhauledPlanCard(plan: p),
          ],
        );
      },
    );
  }
}

class _OverhauledPlanCard extends StatelessWidget {
  const _OverhauledPlanCard({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.id == 'svip'
        ? NutriColors.amber
        : (plan.id == 'vip' ? NutriColors.emerald : NutriColors.blue);
    return NutriCard(
      color: color.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              TierChip(tier: plan.id),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Text(
            plan.id == 'free' ? '0đ' : formatVnd(plan.monthlyPrice),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          for (final f in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    asBool(f['included'])
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: asBool(f['included']) ? color : NutriColors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    asString(f['label']),
                    style: TextStyle(
                      color: asBool(f['included']) ? null : NutriColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (plan.id != 'free')
            FilledButton(
              onPressed: () =>
                  context.go('/checkout?plan=${plan.id}&billing=monthly'),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Nâng cấp ngay'),
            ),
        ],
      ),
    );
  }
}

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
                color: NutriColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn đang đăng ký gói',
                style: TextStyle(color: NutriColors.muted),
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
                  if (context.mounted) context.go('/profile');
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

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const NutriPage(children: [Center(child: Text('Admin Dashboard'))]);
  }
}

class FullCalculatorScreen extends ConsumerStatefulWidget {
  const FullCalculatorScreen({super.key});

  @override
  ConsumerState<FullCalculatorScreen> createState() =>
      _FullCalculatorScreenState();
}

class _FullCalculatorScreenState extends ConsumerState<FullCalculatorScreen> {
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '170');
  final _duration = TextEditingController(text: '30');
  String _gender = 'female';
  String _activity = 'light';
  String _goal = 'maintain';
  String _exerciseType = 'walking';
  CalorieCalculation? _result;
  bool _saving = false;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return NutriPage(
      children: [
        const SectionHeader(
          title: 'Tính toán chỉ số',
          subtitle: 'BMR, TDEE, macro và mục tiêu dinh dưỡng cá nhân.',
        ),
        NutriCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _field(_age, 'Tuổi')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_weight, 'Kg')),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_height, 'Cm')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                ],
                onChanged: (value) =>
                    setState(() => _gender = value ?? _gender),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _activity,
                decoration: const InputDecoration(labelText: 'Mức vận động'),
                items: const [
                  DropdownMenuItem(
                    value: 'sedentary',
                    child: Text('Ít vận động'),
                  ),
                  DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                  DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                  DropdownMenuItem(value: 'active', child: Text('Nhiều')),
                ],
                onChanged: (value) =>
                    setState(() => _activity = value ?? _activity),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _goal,
                decoration: const InputDecoration(labelText: 'Mục tiêu'),
                items: const [
                  DropdownMenuItem(value: 'lose', child: Text('Giảm cân')),
                  DropdownMenuItem(value: 'maintain', child: Text('Duy trì')),
                  DropdownMenuItem(
                    value: 'gain',
                    child: Text('Tăng cơ/tăng cân'),
                  ),
                ],
                onChanged: (value) => setState(() => _goal = value ?? _goal),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _exerciseType,
                      decoration: const InputDecoration(labelText: 'Bài tập'),
                      items: const [
                        DropdownMenuItem(
                          value: 'walking',
                          child: Text('Đi bộ'),
                        ),
                        DropdownMenuItem(value: 'running', child: Text('Chạy')),
                        DropdownMenuItem(
                          value: 'cycling',
                          child: Text('Đạp xe'),
                        ),
                        DropdownMenuItem(value: 'gym', child: Text('Gym')),
                        DropdownMenuItem(value: 'yoga', child: Text('Yoga')),
                      ],
                      onChanged: (value) => setState(
                        () => _exerciseType = value ?? _exerciseType,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_duration, 'Phút tập')),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _calculate,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: const Text('Tính ngay'),
              ),
            ],
          ),
        ),
        if (_result != null) _CalculatorResultCard(result: _result!),
        if (_result != null && session.isLoggedIn)
          FilledButton.tonalIcon(
            onPressed: () => _saveProfile(context),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu làm hồ sơ dinh dưỡng'),
          ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _calculate() async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(apiClientProvider).calculateCalories({
        'age': int.tryParse(_age.text.trim()) ?? 25,
        'weightKg': double.tryParse(_weight.text.trim()) ?? 65,
        'heightCm': double.tryParse(_height.text.trim()) ?? 170,
        'gender': _gender,
        'activityLevel': _activity,
        'goal': _goal,
        'exerciseType': _exerciseType,
        'durationMinutes': int.tryParse(_duration.text.trim()) ?? 30,
      });
      setState(() => _result = result);
    } catch (e) {
      if (mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    final result = _result;
    if (result == null) return;
    try {
      final updated = await ref.read(apiClientProvider).saveNutritionProfile({
        ...result.input,
        'activityLevel': _activity,
        'goal': _goal,
      });
      await ref.read(sessionControllerProvider).syncMember(updated);
      if (context.mounted) showSnack(context, 'Đã lưu hồ sơ dinh dưỡng.');
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class _CalculatorResultCard extends StatelessWidget {
  const _CalculatorResultCard({required this.result});

  final CalorieCalculation result;

  @override
  Widget build(BuildContext context) {
    final r = result.results;
    final macros = asJsonMap(r['macroTargets']);
    return NutriCard(
      color: NutriColors.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Kết quả ước tính'),
          KeyValueLine(label: 'BMR', value: '${asInt(r['bmr'])} kcal'),
          KeyValueLine(label: 'TDEE', value: '${asInt(r['tdee'])} kcal'),
          KeyValueLine(
            label: 'Mục tiêu/ngày',
            value: '${asInt(r['calorieGoal'])} kcal',
          ),
          KeyValueLine(
            label: 'BMI',
            value: '${asDouble(r['bmi']).toStringAsFixed(1)}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Protein ${asInt(macros['protein'])}g')),
              Chip(label: Text('Carbs ${asInt(macros['carbs'])}g')),
              Chip(label: Text('Fat ${asInt(macros['fat'])}g')),
            ],
          ),
          if (result.aiInsight != null) ...[
            const SizedBox(height: 12),
            Text(
              asString(result.aiInsight!['summary']),
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class FullRecipesScreen extends ConsumerStatefulWidget {
  const FullRecipesScreen({super.key});

  @override
  ConsumerState<FullRecipesScreen> createState() => _FullRecipesScreenState();
}

class _FullRecipesScreenState extends ConsumerState<FullRecipesScreen> {
  final _search = TextEditingController();
  late Future<RecipeCollection> _future;
  Future<List<Recipe>>? _savedFuture;
  String _tag = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _savedFuture = ref.read(apiClientProvider).getPersonalizedRecipes();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<RecipeCollection> _load() {
    return ref
        .read(apiClientProvider)
        .getRecipes(search: _search.text.trim(), tag: _tag);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<RecipeCollection>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NutriPage(
              children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
            );
          }
          if (!snapshot.hasData) return const LoadingPanel();
          final data = snapshot.data!;
          final tags = ['Tất cả', ...data.tags];
          return NutriPage(
            children: [
              SectionHeader(
                title: 'Công thức',
                subtitle: 'Tìm món theo tag, calo và tạo gợi ý cá nhân hóa.',
                action: IconButton.filledTonal(
                  tooltip: 'AI cá nhân hóa',
                  onPressed: () => _generatePersonalized(context),
                  icon: const Icon(Icons.auto_awesome),
                ),
              ),
              NutriCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Tìm món hoặc nguyên liệu',
                      ),
                      onSubmitted: (_) => _reload(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          return ChoiceChip(
                            label: Text(tag),
                            selected: tag == _tag,
                            onSelected: (_) {
                              setState(() {
                                _tag = tag;
                                _future = _load();
                              });
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: tags.length,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.access?.recipeLimit != null)
                LockedPanel(
                  title:
                      'Giới hạn công thức ${data.access!.tier.toUpperCase()}',
                  message:
                      'Nâng cấp để xem thêm công thức và dùng AI cá nhân hóa.',
                ),
              FutureBuilder<List<Recipe>>(
                future: _savedFuture,
                builder: (context, savedSnapshot) {
                  final saved = savedSnapshot.data ?? const <Recipe>[];
                  if (saved.isEmpty) return const SizedBox.shrink();
                  return _RecipeHorizontalList(
                    title: 'Đã cá nhân hóa',
                    recipes: saved,
                  );
                },
              ),
              const SectionHeader(title: 'Thư viện món ăn'),
              if (data.recipes.isEmpty)
                const EmptyState(
                  title: 'Chưa có công thức phù hợp',
                  message: 'Thử bỏ bớt bộ lọc hoặc tìm nguyên liệu khác.',
                  icon: Icons.menu_book_outlined,
                )
              else
                for (final recipe in data.recipes)
                  _RecipeListCard(recipe: recipe),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generatePersonalized(BuildContext context) async {
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) => const _PromptDialog(
        title: 'AI cá nhân hóa công thức',
        label: 'Bạn muốn món như thế nào?',
        hint: 'Ví dụ: bữa tối ít carb, giàu protein, nấu dưới 20 phút',
      ),
    );
    if (prompt == null || prompt.trim().isEmpty) return;
    try {
      final api = ref.read(apiClientProvider);
      var result = await api.generatePersonalizedRecipe({'prompt': prompt});
      final questions = jsonMapList(result['questions']);
      if (asString(result['status']) == 'needs_questions' &&
          questions.isNotEmpty &&
          context.mounted) {
        final answers = await showDialog<JsonMap>(
          context: context,
          builder: (context) => _QuestionAnswerDialog(questions: questions),
        );
        if (answers == null) return;
        result = await api.generatePersonalizedRecipe({
          'prompt': prompt,
          'answers': answers,
        });
      }
      final recipe = Recipe.fromJson(result['recipe']);
      setState(() {
        _savedFuture = api.getPersonalizedRecipes();
      });
      if (context.mounted) {
        showSnack(context, 'Đã tạo công thức cá nhân hóa.');
        await showRecipeDetails(context, recipe);
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class _RecipeHorizontalList extends StatelessWidget {
  const _RecipeHorizontalList({required this.title, required this.recipes});

  final String title;
  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return SizedBox(
                width: 240,
                child: _RecipeListCard(recipe: recipe),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: recipes.length,
          ),
        ),
      ],
    );
  }
}

class _RecipeListCard extends StatelessWidget {
  const _RecipeListCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      onTap: () => showRecipeDetails(context, recipe),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: NutriColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: NutriColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${recipe.calories.round()} kcal • ${recipe.timeMinutes} phút • ${recipe.servings} phần',
                  style: const TextStyle(
                    color: NutriColors.muted,
                    fontSize: 12,
                  ),
                ),
                if (recipe.tags.isNotEmpty)
                  Text(
                    recipe.tags.take(3).join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NutriColors.primary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class FullReportsScreen extends ConsumerStatefulWidget {
  const FullReportsScreen({super.key});

  @override
  ConsumerState<FullReportsScreen> createState() => _FullReportsScreenState();
}

class _FullReportsScreenState extends ConsumerState<FullReportsScreen> {
  int _days = 7;
  late Future<NutritionReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<NutritionReport> _load() =>
      ref.read(apiClientProvider).getNutritionReport(days: _days);

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NutritionReport>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) return const LoadingPanel();
        final report = snapshot.data!;
        return NutriPage(
          children: [
            SectionHeader(
              title: 'Báo cáo dinh dưỡng',
              subtitle:
                  '${asString(report.range['from'])} - ${asString(report.range['to'])}',
              action: IconButton.filledTonal(
                tooltip: 'Xuất CSV',
                onPressed: () => _exportReport(context),
                icon: const Icon(Icons.ios_share),
              ),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 ngày')),
                ButtonSegment(value: 14, label: Text('14 ngày')),
                ButtonSegment(value: 30, label: Text('30 ngày')),
              ],
              selected: {_days},
              onSelectionChanged: (value) {
                setState(() {
                  _days = value.first;
                  _future = _load();
                });
              },
            ),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Calo TB',
                    value: '${asInt(report.averages['calories'])}',
                    caption: 'kcal/ngày',
                    icon: Icons.local_fire_department,
                    accent: NutriColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Tuân thủ',
                    value: '${asInt(report.adherence['onTargetPct'])}%',
                    caption: 'mục tiêu calo',
                    icon: Icons.verified_outlined,
                    accent: NutriColors.emerald,
                  ),
                ),
              ],
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Xu hướng calo'),
                  SizedBox(
                    height: 210,
                    child: _CaloriesLineChart(report.daily),
                  ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Bữa ăn'),
                  for (final meal in report.mealBreakdown)
                    KeyValueLine(
                      label: asString(meal['name'], 'Bữa ăn'),
                      value: '${asInt(meal['calories'])} kcal',
                      icon: Icons.restaurant_menu,
                    ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Top món đã ăn'),
                  for (final food in report.topFoods.take(6))
                    KeyValueLine(
                      label: asString(food['name'], asString(food['food'])),
                      value: '${asInt(food['calories'])} kcal',
                      icon: Icons.lunch_dining,
                    ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Phân tích AI'),
                  for (final insight in report.insights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $insight',
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    try {
      final json = await ref
          .read(apiClientProvider)
          .exportNutritionReport(days: _days);
      final content = asString(json['content']);
      await SharePlus.instance.share(
        ShareParams(
          text: content,
          subject: asString(json['filename'], 'nutripath-report.csv'),
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      await Clipboard.setData(
        ClipboardData(text: 'Không thể xuất báo cáo: ${readableError(e)}'),
      );
      showSnack(context, readableError(e));
    }
  }
}

class _CaloriesLineChart extends StatelessWidget {
  const _CaloriesLineChart(this.daily);

  final List<JsonMap> daily;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < daily.length; i++) {
      spots.add(FlSpot(i.toDouble(), asDouble(daily[i]['calories'])));
    }
    if (spots.isEmpty) {
      return const Center(child: Text('Chưa đủ dữ liệu để vẽ biểu đồ.'));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            color: NutriColors.primary,
            belowBarData: BarAreaData(
              show: true,
              color: NutriColors.primary.withValues(alpha: 0.12),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class FullProfileScreen extends ConsumerStatefulWidget {
  const FullProfileScreen({super.key});

  @override
  ConsumerState<FullProfileScreen> createState() => _FullProfileScreenState();
}

class _FullProfileScreenState extends ConsumerState<FullProfileScreen> {
  late Future<_ProfileBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileBundle> _load() async {
    final api = ref.read(apiClientProvider);
    final results = await Future.wait<Object>([
      api.getProfile(),
      api.getNotifications(limit: 8),
      api.getPayments(),
    ]);
    return _ProfileBundle(
      profile: results[0] as JsonMap,
      notifications: results[1] as List<AppNotification>,
      payments: results[2] as List<Payment>,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();
    return FutureBuilder<_ProfileBundle>(
      future: _future,
      builder: (context, snapshot) {
        final profile = snapshot.data?.profile ?? const <String, dynamic>{};
        final plan = asJsonMap(profile['plan']);
        final benefits = jsonMapList(profile['benefits']);
        final notifications =
            snapshot.data?.notifications ?? const <AppNotification>[];
        final payments = snapshot.data?.payments ?? const <Payment>[];
        return NutriPage(
          children: [
            NutriCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: NutriColors.primary.withValues(
                      alpha: 0.12,
                    ),
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
                    style: const TextStyle(color: NutriColors.muted),
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
            if (snapshot.hasError)
              ErrorPanel(error: snapshot.error!, onRetry: _reload)
            else if (!snapshot.hasData)
              const LoadingPanel()
            else ...[
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Gói hiện tại',
                      action: TextButton(
                        onPressed: () => context.go('/pricing'),
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
                                ? NutriColors.emerald
                                : NutriColors.muted,
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
                          _reload();
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
                                ? NutriColors.amber
                                : NutriColors.muted,
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
                                  _reload();
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
            ],
            NutriCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.logout, color: NutriColors.red),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  await ref.read(sessionControllerProvider).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProfile(BuildContext context, Member member) async {
    final payload = await showModalBottomSheet<JsonMap>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProfileEditSheet(member: member),
    );
    if (payload == null) return;
    try {
      final updated = await ref
          .read(apiClientProvider)
          .updateMemberProfile(payload);
      await ref.read(sessionControllerProvider).syncMember(updated);
      _reload();
      if (context.mounted) showSnack(context, 'Đã cập nhật hồ sơ.');
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class _ProfileBundle {
  const _ProfileBundle({
    required this.profile,
    required this.notifications,
    required this.payments,
  });

  final JsonMap profile;
  final List<AppNotification> notifications;
  final List<Payment> payments;
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({required this.member});

  final Member member;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _calories;
  late final TextEditingController _water;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member.name);
    _email = TextEditingController(text: widget.member.email);
    _calories = TextEditingController(text: '${widget.member.calorieTarget}');
    _water = TextEditingController(text: '${widget.member.waterTargetGlasses}');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _calories.dispose();
    _water.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionHeader(title: 'Chỉnh hồ sơ'),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Họ tên'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Mục tiêu calo/ngày'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _water,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mục tiêu nước ly/ngày',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'calorieTarget':
                  int.tryParse(_calories.text.trim()) ??
                  widget.member.calorieTarget,
              'waterTargetGlasses':
                  int.tryParse(_water.text.trim()) ??
                  widget.member.waterTargetGlasses,
            }),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}

class FullPricingScreen extends ConsumerStatefulWidget {
  const FullPricingScreen({super.key});

  @override
  ConsumerState<FullPricingScreen> createState() => _FullPricingScreenState();
}

class _FullPricingScreenState extends ConsumerState<FullPricingScreen> {
  String _billing = 'monthly';
  late Future<_PricingBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PricingBundle> _load() async {
    final api = ref.read(apiClientProvider);
    final results = await Future.wait<Object>([
      api.getPlans(_billing),
      api.getFaqs(),
    ]);
    return _PricingBundle(
      plans: results[0] as List<Plan>,
      faqs: results[1] as List<JsonMap>,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PricingBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) return const LoadingPanel();
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Gói hội viên',
              subtitle:
                  'Free, VIP và SVIP theo đúng quyền truy cập từ backend.',
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Tháng')),
                ButtonSegment(value: 'annual', label: Text('Năm')),
              ],
              selected: {_billing},
              onSelectionChanged: (value) {
                setState(() {
                  _billing = value.first;
                  _future = _load();
                });
              },
            ),
            for (final plan in snapshot.data!.plans)
              _FullPlanCard(plan: plan, billing: _billing),
            const SectionHeader(title: 'Câu hỏi thường gặp'),
            for (final faq in snapshot.data!.faqs)
              ExpansionTile(
                title: Text(
                  asString(faq['question']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      asString(faq['answer']),
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _PricingBundle {
  const _PricingBundle({required this.plans, required this.faqs});

  final List<Plan> plans;
  final List<JsonMap> faqs;
}

class _FullPlanCard extends StatelessWidget {
  const _FullPlanCard({required this.plan, required this.billing});

  final Plan plan;
  final String billing;

  @override
  Widget build(BuildContext context) {
    final color = switch (plan.id) {
      'svip' => NutriColors.amber,
      'vip' => NutriColors.emerald,
      _ => NutriColors.blue,
    };
    final quote = plan.pricePreview;
    final price = quote?.total ?? plan.monthlyPrice;
    return NutriCard(
      color: color.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              TierChip(tier: plan.id),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.description),
          const SizedBox(height: 14),
          Text(
            plan.id == 'free' ? '0đ' : formatVnd(price),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(
            billing == 'annual'
                ? 'thanh toán theo năm'
                : 'thanh toán theo tháng',
          ),
          const SizedBox(height: 14),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    asBool(feature['included'])
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: asBool(feature['included'])
                        ? color
                        : NutriColors.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(asString(feature['label']))),
                ],
              ),
            ),
          if (plan.id != 'free') ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.go('/checkout?plan=${plan.id}&billing=$billing'),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Chọn gói này'),
            ),
          ],
        ],
      ),
    );
  }
}

class FullCheckoutScreen extends ConsumerStatefulWidget {
  const FullCheckoutScreen({
    required this.initialPlanId,
    required this.initialBilling,
    super.key,
  });

  final String initialPlanId;
  final String initialBilling;

  @override
  ConsumerState<FullCheckoutScreen> createState() => _FullCheckoutScreenState();
}

class _FullCheckoutScreenState extends ConsumerState<FullCheckoutScreen> {
  final _discount = TextEditingController();
  String _paymentMethod = 'demo';
  int _trialDays = 0;
  late String _billing;
  late Future<CheckoutQuote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _billing = widget.initialBilling;
    _quoteFuture = _quote();
  }

  @override
  void dispose() {
    _discount.dispose();
    super.dispose();
  }

  Future<CheckoutQuote> _quote() {
    return ref
        .read(apiClientProvider)
        .getCheckoutQuote(
          planId: widget.initialPlanId,
          billing: _billing,
          discountCode: _discount.text.trim(),
          trialDays: _trialDays,
        );
  }

  void _reloadQuote() => setState(() => _quoteFuture = _quote());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CheckoutQuote>(
      future: _quoteFuture,
      builder: (context, snapshot) {
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Thanh toán',
              subtitle: 'Checkout demo không lưu thông tin thẻ.',
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Tháng')),
                ButtonSegment(value: 'annual', label: Text('Năm')),
              ],
              selected: {_billing},
              onSelectionChanged: (value) {
                setState(() {
                  _billing = value.first;
                  _quoteFuture = _quote();
                });
              },
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.initialPlanId.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discount,
                    decoration: const InputDecoration(
                      labelText: 'Mã giảm giá',
                      hintText: 'NUTRIPATH10',
                    ),
                    onSubmitted: (_) => _reloadQuote(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dùng thử 7 ngày'),
                    value: _trialDays == 7,
                    onChanged: (value) {
                      setState(() {
                        _trialDays = value ? 7 : 0;
                        _quoteFuture = _quote();
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Phương thức'),
                    items: const [
                      DropdownMenuItem(value: 'demo', child: Text('Ví demo')),
                      DropdownMenuItem(value: 'card', child: Text('Thẻ demo')),
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Chuyển khoản demo'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _paymentMethod = value ?? _paymentMethod,
                    ),
                  ),
                ],
              ),
            ),
            if (snapshot.hasError)
              ErrorPanel(error: snapshot.error!, onRetry: _reloadQuote)
            else if (!snapshot.hasData)
              const LoadingPanel()
            else
              _QuoteCard(quote: snapshot.data!),
            FilledButton.icon(
              onPressed: snapshot.hasData ? () => _pay(context) : null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Xác nhận thanh toán demo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pay(BuildContext context) async {
    try {
      final (_, updated) = await ref.read(apiClientProvider).createPayment({
        'planId': widget.initialPlanId,
        'billing': _billing,
        'paymentMethod': _paymentMethod,
        'discountCode': _discount.text.trim(),
        'trialDays': _trialDays,
      });
      await ref.read(sessionControllerProvider).syncMember(updated);
      if (context.mounted) {
        showSnack(
          context,
          'Gói ${widget.initialPlanId.toUpperCase()} đã được kích hoạt.',
        );
        context.go('/profile');
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final CheckoutQuote quote;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Tóm tắt đơn hàng'),
          KeyValueLine(label: 'Gói', value: quote.planName),
          KeyValueLine(label: 'Chu kỳ', value: quote.billing),
          KeyValueLine(label: 'Tạm tính', value: formatVnd(quote.subtotal)),
          KeyValueLine(label: 'VAT', value: formatVnd(quote.vat)),
          if (quote.discountAmount > 0)
            KeyValueLine(
              label: 'Giảm giá',
              value: '-${formatVnd(quote.discountAmount)}',
            ),
          if (quote.trialDays > 0)
            KeyValueLine(label: 'Dùng thử', value: '${quote.trialDays} ngày'),
          const Divider(),
          KeyValueLine(label: 'Tổng thanh toán', value: formatVnd(quote.total)),
        ],
      ),
    );
  }
}

class FullAdminScreen extends ConsumerStatefulWidget {
  const FullAdminScreen({super.key});

  @override
  ConsumerState<FullAdminScreen> createState() => _FullAdminScreenState();
}

class _FullAdminScreenState extends ConsumerState<FullAdminScreen> {
  late Future<_AdminBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminBundle> _load() async {
    final api = ref.read(apiClientProvider);
    final results = await Future.wait<Object>([
      api.getAdminOverview(),
      api.getAdminUsers(),
      api.getAdminContent(),
      api.getAdminAnalytics(),
      api.getAdminSystem(),
      api.getAdminAiSettings(),
      api.getAdminSecurity(),
      api.getAdminAiSafetyLogs(),
    ]);
    return _AdminBundle(
      overview: results[0] as AdminOverview,
      users: results[1] as JsonMap,
      content: results[2] as JsonMap,
      analytics: results[3] as JsonMap,
      system: results[4] as JsonMap,
      aiSettings: results[5] as JsonMap,
      security: results[6] as JsonMap,
      safetyLogs: results[7] as JsonMap,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) return const LoadingPanel();
        final data = snapshot.data!;
        return DefaultTabController(
          length: 6,
          child: NutriPage(
            children: [
              SectionHeader(
                title: 'Admin',
                subtitle: 'Quản trị user, content, analytics, AI và bảo mật.',
                action: IconButton.filledTonal(
                  tooltip: 'Tải lại',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Users'),
                  Tab(text: 'Content'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'AI'),
                  Tab(text: 'System'),
                ],
              ),
              SizedBox(
                height: 720,
                child: TabBarView(
                  children: [
                    _AdminOverviewTab(data.overview),
                    _AdminUsersTab(data.users),
                    _AdminContentTab(data.content),
                    _AdminAnalyticsTab(data.analytics),
                    _AdminAiSecurityTab(
                      aiSettings: data.aiSettings,
                      security: data.security,
                      safetyLogs: data.safetyLogs,
                      onToggleAi: _updateAiSetting,
                      onToggleSecurity: _updateSecurity,
                    ),
                    _AdminSystemTab(data.system),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAiSetting(String key, bool value) async {
    await ref.read(apiClientProvider).updateAdminAiSettings({key: value});
    _reload();
  }

  Future<void> _updateSecurity(String key, bool value) async {
    await ref.read(apiClientProvider).updateAdminSecurity({key: value});
    _reload();
  }
}

class _AdminBundle {
  const _AdminBundle({
    required this.overview,
    required this.users,
    required this.content,
    required this.analytics,
    required this.system,
    required this.aiSettings,
    required this.security,
    required this.safetyLogs,
  });

  final AdminOverview overview;
  final JsonMap users;
  final JsonMap content;
  final JsonMap analytics;
  final JsonMap system;
  final JsonMap aiSettings;
  final JsonMap security;
  final JsonMap safetyLogs;
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab(this.overview);

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final kpi in overview.kpis)
          MetricCard(
            label: asString(kpi['label']),
            value: asString(kpi['value']),
            caption: asString(kpi['delta']),
            icon: Icons.insights,
          ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Người dùng mới'),
        for (final user in overview.recentUsers)
          ListTile(
            title: Text(asString(user['name'])),
            subtitle: Text(asString(user['email'])),
            trailing: Text(asString(user['tier']).toUpperCase()),
          ),
      ],
    );
  }
}

class _AdminUsersTab extends StatelessWidget {
  const _AdminUsersTab(this.users);

  final JsonMap users;

  @override
  Widget build(BuildContext context) {
    final items = embeddedList(users, 'users');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '${items.length} tài khoản',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (final user in items)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(asString(user['name'])),
            subtitle: Text(
              '${asString(user['email'])} • ${asString(user['role'])}',
            ),
            trailing: TierChip(tier: asString(user['tier'], 'free')),
          ),
      ],
    );
  }
}

class _AdminContentTab extends StatelessWidget {
  const _AdminContentTab(this.content);

  final JsonMap content;

  @override
  Widget build(BuildContext context) {
    final foods = jsonMapList(content['foods']);
    final recipes = jsonMapList(content['recipes']);
    final plans = jsonMapList(content['mealPlans']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Foods',
                value: '${foods.length}',
                icon: Icons.fastfood,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Recipes',
                value: '${recipes.length}',
                icon: Icons.menu_book,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Plan content'),
        for (final plan in plans)
          KeyValueLine(
            label: asString(plan['name']),
            value: '${asInt(plan['meals'])} quyền',
            icon: Icons.workspace_premium,
          ),
      ],
    );
  }
}

class _AdminAnalyticsTab extends StatelessWidget {
  const _AdminAnalyticsTab(this.analytics);

  final JsonMap analytics;

  @override
  Widget build(BuildContext context) {
    final daily = jsonMapList(analytics['dailyMeals']);
    final top = jsonMapList(analytics['topDishes']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader(title: 'Meal activity 7 ngày'),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: [
                for (var i = 0; i < daily.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: asDouble(daily[i]['meals']),
                        color: NutriColors.primary,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Top món'),
        for (final dish in top.take(8))
          KeyValueLine(
            label: '#${asInt(dish['rank'])} ${asString(dish['dish'])}',
            value: '${asInt(dish['searches'])} lượt',
            icon: Icons.restaurant,
          ),
      ],
    );
  }
}

class _AdminAiSecurityTab extends StatelessWidget {
  const _AdminAiSecurityTab({
    required this.aiSettings,
    required this.security,
    required this.safetyLogs,
    required this.onToggleAi,
    required this.onToggleSecurity,
  });

  final JsonMap aiSettings;
  final JsonMap security;
  final JsonMap safetyLogs;
  final Future<void> Function(String key, bool value) onToggleAi;
  final Future<void> Function(String key, bool value) onToggleSecurity;

  @override
  Widget build(BuildContext context) {
    final settings = asJsonMap(aiSettings['settings']);
    final securityMap = asJsonMap(security['security']);
    final logs = jsonMapList(safetyLogs['logs']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader(title: 'AI settings'),
        for (final entry in settings.entries)
          _AdminSettingTile(entry: entry, onToggle: onToggleAi),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Security'),
        for (final entry in securityMap.entries)
          _AdminSettingTile(entry: entry, onToggle: onToggleSecurity),
        const SizedBox(height: 12),
        SectionHeader(title: 'AI safety logs (${logs.length})'),
        for (final log in logs.take(8))
          ListTile(
            title: Text(asString(log['reason'], asString(log['type'], 'Log'))),
            subtitle: Text(asString(log['createdAt'])),
            trailing: Text(asString(log['severity'], 'info')),
          ),
      ],
    );
  }
}

class _AdminSettingTile extends StatelessWidget {
  const _AdminSettingTile({required this.entry, required this.onToggle});

  final MapEntry<String, dynamic> entry;
  final Future<void> Function(String key, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (entry.value is bool) {
      return SwitchListTile(
        title: Text(entry.key),
        value: entry.value as bool,
        onChanged: (value) => onToggle(entry.key, value),
      );
    }
    return KeyValueLine(label: entry.key, value: asString(entry.value));
  }
}

class _AdminSystemTab extends StatelessWidget {
  const _AdminSystemTab(this.system);

  final JsonMap system;

  @override
  Widget build(BuildContext context) {
    final services = jsonMapList(system['services']);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final service in services)
          ListTile(
            leading: Icon(
              asString(service['status']).toLowerCase().contains('ok')
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: asString(service['status']).toLowerCase().contains('ok')
                  ? NutriColors.emerald
                  : NutriColors.amber,
            ),
            title: Text(asString(service['name'])),
            subtitle: Text(
              asString(service['description'], asString(service['status'])),
            ),
            trailing: Text(asString(service['status']).toUpperCase()),
          ),
      ],
    );
  }
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.hint,
  });

  final String title;
  final String label;
  final String hint;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Gửi'),
        ),
      ],
    );
  }
}

class _QuestionAnswerDialog extends StatefulWidget {
  const _QuestionAnswerDialog({required this.questions});

  final List<JsonMap> questions;

  @override
  State<_QuestionAnswerDialog> createState() => _QuestionAnswerDialogState();
}

class _QuestionAnswerDialogState extends State<_QuestionAnswerDialog> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [for (final _ in widget.questions) TextEditingController()];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bổ sung thông tin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.questions.length; i++) ...[
              TextField(
                controller: _controllers[i],
                decoration: InputDecoration(
                  labelText: asString(
                    widget.questions[i]['label'],
                    'Câu hỏi ${i + 1}',
                  ),
                  hintText: asString(widget.questions[i]['placeholder']),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final answers = <String, dynamic>{};
            for (var i = 0; i < widget.questions.length; i++) {
              final key = asString(widget.questions[i]['id'], 'q$i');
              answers[key] = _controllers[i].text.trim();
            }
            Navigator.pop(context, answers);
          },
          child: const Text('Tạo công thức'),
        ),
      ],
    );
  }
}

Future<void> showRecipeDetails(BuildContext context, Recipe r) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            r.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _rChip(Icons.timer_outlined, '${r.timeMinutes} phút'),
              const SizedBox(width: 8),
              _rChip(
                Icons.local_fire_department_outlined,
                '${r.calories.round()} kcal',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Nguyên liệu'),
          for (final i in r.ingredients)
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 6),
              title: Text('${asString(i['name'])}: ${asString(i['amount'])}'),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Hướng dẫn'),
          for (var i = 0; i < r.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${i + 1}. ${r.steps[i]}',
                style: const TextStyle(height: 1.5),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _rChip(IconData i, String l) => Chip(
  avatar: Icon(i, size: 14),
  label: Text(l, style: const TextStyle(fontSize: 12)),
);
