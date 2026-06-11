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
              child:
                  session.busy
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
              const Icon(Icons.auto_awesome, color: NutriColors.primary, size: 20),
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
                style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
                onPressed:
                    current > 0
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
        builder:
            (context) => AlertDialog(
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
      final res = await ref
          .read(apiClientProvider)
          .estimateCustomFood(payload);
      if (!context.mounted) return;
      final addable = asJsonMap(res['addableItem']);
      if (addable.isNotEmpty) {
        await ref
            .read(apiClientProvider)
            .addMealItem(localDateString(date), meal.id, addable);
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
                  style: FilledButton.styleFrom(backgroundColor: NutriColors.amber),
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
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                suffixIcon: IconButton(onPressed: _run, icon: const Icon(Icons.search)),
              ),
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<Food>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final foods = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: foods.length,
                    itemBuilder: (context, i) {
                      final f = foods[i];
                      return ListTile(
                        title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
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
        const SectionHeader(title: 'Tính toán chỉ số', subtitle: 'BMR, TDEE và nhu cầu dinh dưỡng.'),
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
                  final r = await ref.read(apiClientProvider).calculateCalories({
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
                _resLine('Mục tiêu hàng ngày', '${_res!.results['calorieGoal']} kcal'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _f(TextEditingController c, String l) => TextFormField(controller: c, decoration: InputDecoration(labelText: l));
  Widget _resLine(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: const TextStyle(fontWeight: FontWeight.w900))]),
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
            const SectionHeader(title: 'Khám phá công thức', subtitle: 'Hàng ngàn món ăn healthy từ chuyên gia.'),
            for (final r in recipes)
              NutriCard(
                onTap: () => showRecipeDetails(context, r),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: NutriColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.restaurant, color: NutriColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('${r.calories.round()} kcal • ${r.timeMinutes} phút', style: const TextStyle(color: NutriColors.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: NutriColors.slate300),
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
            const SectionHeader(title: 'Báo cáo tuần', subtitle: 'Phân tích thói quen ăn uống của bạn.'),
            NutriCard(
              child: Column(
                children: [
                  const Text('Calo trung bình ngày', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${rep.averages['calories'].round()} kcal', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: NutriColors.primary)),
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
                    Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $ins', style: const TextStyle(height: 1.4))),
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
              CircleAvatar(radius: 40, backgroundColor: NutriColors.primary.withValues(alpha: 0.1), child: Text(member.initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
              const SizedBox(height: 16),
              Text(member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(member.email, style: const TextStyle(color: NutriColors.muted)),
              const SizedBox(height: 16),
              TierChip(tier: member.tier),
            ],
          ),
        ),
        NutriCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(leading: const Icon(Icons.workspace_premium, color: NutriColors.amber), title: const Text('Gói thành viên'), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/pricing')),
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
            const SectionHeader(title: 'Nâng cấp hội viên', subtitle: 'Mở khóa toàn bộ tính năng AI.'),
            for (final p in snapshot.data!)
              _OverhauledPlanCard(plan: p),
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
    final color = plan.id == 'svip' ? NutriColors.amber : (plan.id == 'vip' ? NutriColors.emerald : NutriColors.blue);
    return NutriCard(
      color: color.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              TierChip(tier: plan.id),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.description, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Text(plan.id == 'free' ? '0đ' : formatVnd(plan.monthlyPrice), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          for (final f in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(asBool(f['included']) ? Icons.check_circle : Icons.circle_outlined, size: 16, color: asBool(f['included']) ? color : NutriColors.muted),
                  const SizedBox(width: 8),
                  Text(asString(f['label']), style: TextStyle(color: asBool(f['included']) ? null : NutriColors.muted)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (plan.id != 'free')
            FilledButton(
              onPressed: () => context.go('/checkout?plan=${plan.id}&billing=monthly'),
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Nâng cấp ngay'),
            ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({required this.initialPlanId, required this.initialBilling, super.key});
  final String initialPlanId, initialBilling;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    return NutriPage(
      children: [
        const SectionHeader(title: 'Thanh toán', subtitle: 'Mô phỏng quy trình thanh toán.'),
        NutriCard(
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 48, color: NutriColors.primary),
              const SizedBox(height: 16),
              const Text('Bạn đang đăng ký gói', style: TextStyle(color: NutriColors.muted)),
              Text(widget.initialPlanId.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final (_, updated) = await ref.read(apiClientProvider).createPayment({
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
          Text(r.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(
            children: [
              _rChip(Icons.timer_outlined, '${r.timeMinutes} phút'),
              const SizedBox(width: 8),
              _rChip(Icons.local_fire_department_outlined, '${r.calories.round()} kcal'),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Nguyên liệu'),
          for (final i in r.ingredients) ListTile(dense: true, leading: const Icon(Icons.circle, size: 6), title: Text('${asString(i['name'])}: ${asString(i['amount'])}')),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Hướng dẫn'),
          for (var i = 0; i < r.steps.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('${i + 1}. ${r.steps[i]}', style: const TextStyle(height: 1.5))),
        ],
      ),
    ),
  );
}

Widget _rChip(IconData i, String l) => Chip(avatar: Icon(i, size: 14), label: Text(l, style: const TextStyle(fontSize: 12)));
