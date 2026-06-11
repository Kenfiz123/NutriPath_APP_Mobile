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

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Nhập email';
  if (!_emailPattern.hasMatch(email)) return 'Email không đúng định dạng';
  return null;
}

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Nhập mật khẩu';
  if (password.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự';
  return null;
}

String? _validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Nhập họ tên';
  if (name.length < 2) return 'Họ tên cần ít nhất 2 ký tự';
  return null;
}

String? _validateNumberRange(
  String? value, {
  required String label,
  required num min,
  required num max,
}) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Nhập $label';
  final parsed = num.tryParse(raw.replaceAll(',', '.'));
  if (parsed == null) return '$label phải là số';
  if (parsed < min || parsed > max) {
    return '$label phải từ ${formatNumber(min)} đến ${formatNumber(max)}';
  }
  return null;
}

double _parseInputDouble(String value) {
  return double.parse(value.trim().replaceAll(',', '.'));
}

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
    setState(() {
      _formError = null;
    });
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Vui lòng kiểm tra email và mật khẩu.';
      });
      return;
    }
    try {
      await ref
          .read(sessionControllerProvider)
          .login(_email.text.trim(), _password.text);
      if (!mounted) return;
      context.go(widget.from ?? '/dashboard');
    } catch (error) {
      if (!mounted) return;
      final message = readableError(error);
      setState(() {
        _formError = message;
      });
      showSnack(context, message);
    }
  }

  void _clearFormError() {
    ref.read(sessionControllerProvider).clearError();
    if (_formError == null) return;
    setState(() {
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final visibleError = _formError ?? session.error;
    return _AuthScaffold(
      title: 'Chào mừng trở lại',
      subtitle: 'Đăng nhập để đồng bộ bữa ăn, báo cáo và gói hội viên.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            if (visibleError != null && visibleError.trim().isNotEmpty) ...[
              _AuthErrorBanner(message: visibleError),
              const SizedBox(height: NutriSpacing.md),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !session.busy,
              onChanged: (_) => _clearFormError(),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: NutriSpacing.md),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !session.busy,
              onChanged: (_) => _clearFormError(),
              onFieldSubmitted: (_) => session.busy ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: session.busy
                      ? null
                      : () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: NutriSpacing.lg),
            FilledButton.icon(
              onPressed: session.busy ? null : _submit,
              icon: session.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Đăng nhập'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Chưa có tài khoản? Đăng ký'),
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
  bool _obscurePassword = true;
  String _gender = 'female';
  String _activityLevel = 'light';
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
    ref.read(sessionControllerProvider).clearError();
    setState(() {
      _formError = null;
    });
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Vui lòng kiểm tra thông tin đăng ký.';
      });
      return;
    }
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'gender': _gender,
      'age': _parseInputDouble(_age.text).round(),
      'weightKg': _parseInputDouble(_weight.text),
      'heightCm': _parseInputDouble(_height.text),
      'activityLevel': _activityLevel,
      'goal': _goal,
    };
    try {
      await ref.read(sessionControllerProvider).register(payload);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      final message = readableError(error);
      setState(() {
        _formError = message;
      });
      showSnack(context, message);
    }
  }

  void _clearFormError() {
    ref.read(sessionControllerProvider).clearError();
    if (_formError == null) return;
    setState(() {
      _formError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final visibleError = _formError ?? session.error;
    return _AuthScaffold(
      title: 'Tạo tài khoản NutriPath',
      subtitle: 'Thiết lập hồ sơ dinh dưỡng ban đầu cho app.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            if (visibleError != null && visibleError.trim().isNotEmpty) ...[
              _AuthErrorBanner(message: visibleError),
              const SizedBox(height: NutriSpacing.md),
            ],
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              enabled: !session.busy,
              onChanged: (_) => _clearFormError(),
              decoration: const InputDecoration(
                labelText: 'Họ tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: NutriSpacing.md),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !session.busy,
              onChanged: (_) => _clearFormError(),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: NutriSpacing.md),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !session.busy,
              onChanged: (_) => _clearFormError(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: session.busy
                      ? null
                      : () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: NutriSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    _age,
                    'Tuổi',
                    min: 13,
                    max: 100,
                    suffix: 'tuổi',
                  ),
                ),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(
                  child: _numberField(
                    _weight,
                    'Cân nặng',
                    min: 25,
                    max: 250,
                    suffix: 'kg',
                    allowDecimal: true,
                  ),
                ),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(
                  child: _numberField(
                    _height,
                    'Chiều cao',
                    min: 100,
                    max: 230,
                    suffix: 'cm',
                    allowDecimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NutriSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                DropdownMenuItem(value: 'male', child: Text('Nam')),
              ],
              onChanged: session.busy
                  ? null
                  : (value) => setState(() => _gender = value ?? _gender),
            ),
            const SizedBox(height: NutriSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(labelText: 'Mức vận động'),
              items: const [
                DropdownMenuItem(
                  value: 'sedentary',
                  child: Text('Ít vận động'),
                ),
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'active', child: Text('Năng động')),
              ],
              onChanged: session.busy
                  ? null
                  : (value) => setState(
                      () => _activityLevel = value ?? _activityLevel,
                    ),
            ),
            const SizedBox(height: NutriSpacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'lose', label: Text('Giảm')),
                ButtonSegment(value: 'maintain', label: Text('Giữ')),
                ButtonSegment(value: 'gain', label: Text('Tăng')),
              ],
              selected: {_goal},
              onSelectionChanged: session.busy
                  ? null
                  : (values) => setState(() => _goal = values.first),
            ),
            const SizedBox(height: NutriSpacing.lg),
            FilledButton.icon(
              onPressed: session.busy ? null : _submit,
              icon: session.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(
                session.busy ? 'Đang tạo tài khoản...' : 'Tạo tài khoản',
              ),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required num min,
    required num max,
    required String suffix,
    bool allowDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !ref.watch(sessionControllerProvider).busy,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[0-9,.]') : RegExp(r'[0-9]'),
        ),
      ],
      onChanged: (_) => _clearFormError(),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) =>
          _validateNumberRange(value, label: label, min: min, max: max),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NutriSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: NutriSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.eco, color: Colors.white),
                    ),
                    const SizedBox(width: NutriSpacing.md),
                    Text(
                      'NutriPath',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                NutriCard(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  void _reload() {
    setState(() {
      _future = ref
          .read(apiClientProvider)
          .getDashboard(date: localDateString());
    });
  }

  Future<void> _coachPlan() async {
    try {
      await ref.read(apiClientProvider).createWeeklyCoachPlan();
      if (!mounted) return;
      showSnack(context, 'Đã tạo kế hoạch coach tuần này.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();

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
          if (!snapshot.hasData) {
            return const NutriPage(
              children: [LoadingPanel(message: 'Đang tải dashboard...')],
            );
          }
          final data = snapshot.data!;
          final summary = data.nutrition;
          final target = summary.targets.calories == 0
              ? 1
              : summary.targets.calories;
          return NutriPage(
            children: [
              NutriCard(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.09),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${data.greeting}, ${data.member.name}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        TierChip(tier: data.member.tier),
                      ],
                    ),
                    const SizedBox(height: NutriSpacing.sm),
                    Text(
                      'Mục tiêu hôm nay: ${formatNumber(target)} kcal, ${data.member.waterTargetGlasses} ly nước.',
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 560;
                  final cards = [
                    MetricCard(
                      label: 'Calo đã nạp',
                      value: '${formatNumber(summary.totals.calories)} kcal',
                      caption:
                          'Còn ${formatNumber(summary.remainingCalories)} kcal',
                      icon: Icons.local_fire_department_outlined,
                      accent: NutriColors.primary,
                    ),
                    MetricCard(
                      label: 'Protein',
                      value:
                          '${formatNumber(summary.totals.protein, digits: 1)} g',
                      caption:
                          'Mục tiêu ${formatNumber(summary.targets.protein)} g',
                      icon: Icons.fitness_center,
                      accent: NutriColors.blue,
                    ),
                    MetricCard(
                      label: 'Nước',
                      value:
                          '${data.mealLog.waterGlasses}/${formatNumber(summary.targets.waterGlasses)} ly',
                      caption: 'Theo dõi hydrate mỗi ngày',
                      icon: Icons.water_drop_outlined,
                      accent: NutriColors.teal,
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: wide ? 3 : 1,
                    mainAxisSpacing: NutriSpacing.md,
                    crossAxisSpacing: NutriSpacing.md,
                    childAspectRatio: wide ? 1.62 : 3.9,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: cards,
                  );
                },
              ),
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Tiến độ calo',
                      subtitle: 'So với mục tiêu cá nhân hôm nay',
                    ),
                    const SizedBox(height: NutriSpacing.md),
                    ProgressLine(value: summary.totals.calories / target),
                    const SizedBox(height: NutriSpacing.sm),
                    Text('${summary.calorieProgressPct}% mục tiêu'),
                  ],
                ),
              ),
              _WeeklyProgressChart(points: data.weeklyProgress),
              _MealPreview(log: data.mealLog),
              if (data.tips.isNotEmpty)
                NutriCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Gợi ý hôm nay'),
                      const SizedBox(height: NutriSpacing.sm),
                      for (final tip in data.tips)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lightbulb_outline),
                          title: Text(tip),
                        ),
                    ],
                  ),
                ),
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Thao tác nhanh'),
                    const SizedBox(height: NutriSpacing.md),
                    Wrap(
                      spacing: NutriSpacing.sm,
                      runSpacing: NutriSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/tracker'),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm bữa ăn'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showChatSheet(context),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat AI'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/recipes'),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Công thức'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/reports'),
                          icon: const Icon(Icons.insert_chart_outlined),
                          label: const Text('Báo cáo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (data.member.canUseCoach)
                _CoachPlansCard(
                  api: ref.read(apiClientProvider),
                  onCreate: _coachPlan,
                )
              else
                const LockedPanel(
                  title: 'AI Coach dành cho SVIP',
                  message: 'Nâng cấp SVIP để có kế hoạch tuần cá nhân hóa.',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CoachPlansCard extends StatefulWidget {
  const _CoachPlansCard({required this.api, required this.onCreate});

  final ApiClient api;
  final Future<void> Function() onCreate;

  @override
  State<_CoachPlansCard> createState() => _CoachPlansCardState();
}

class _CoachPlansCardState extends State<_CoachPlansCard> {
  late Future<List<WeeklyCoachPlan>> _future;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getWeeklyCoachPlans();
  }

  void _reload() {
    setState(() {
      _future = widget.api.getWeeklyCoachPlans();
    });
  }

  Future<void> _create() async {
    if (_creating) return;
    setState(() {
      _creating = true;
    });
    try {
      await widget.onCreate();
      if (!mounted) return;
      _reload();
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  Widget _metricChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<WeeklyCoachPlan>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorPanel(error: snapshot.error!, onRetry: _reload);
        }
        if (!snapshot.hasData) {
          return const LoadingPanel(message: 'Đang tải kế hoạch AI Coach...');
        }

        final plans = snapshot.data!;
        final latest = plans.isEmpty ? null : plans.first;
        final subtitle = latest == null
            ? 'Chưa có kế hoạch tuần nào.'
            : '${friendlyDate(latest.startDate)} - ${friendlyDate(latest.endDate)}';

        return NutriCard(
          color: NutriColors.amber.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Kế hoạch AI Coach',
                subtitle: subtitle,
                action: IconButton.filledTonal(
                  tooltip: 'Làm mới kế hoạch',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(height: NutriSpacing.md),
              if (latest == null)
                _EmptyCoachPlan(onCreate: _create, creating: _creating)
              else ...[
                Text(
                  latest.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (latest.summary.isNotEmpty) ...[
                  const SizedBox(height: NutriSpacing.xs),
                  Text(
                    latest.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: NutriSpacing.md),
                Wrap(
                  spacing: NutriSpacing.sm,
                  runSpacing: NutriSpacing.sm,
                  children: [
                    _metricChip(
                      Icons.local_fire_department_outlined,
                      '${formatNumber(latest.targetCalories)} kcal/ngày',
                    ),
                    _metricChip(
                      Icons.fitness_center,
                      'Protein ${formatNumber(latest.macroTargets.protein)}g',
                    ),
                    if (latest.generatedAt.isNotEmpty)
                      _metricChip(
                        Icons.schedule,
                        'Tạo ${friendlyDate(latest.generatedAt)}',
                      ),
                  ],
                ),
                if (latest.actionSteps.isNotEmpty) ...[
                  const SizedBox(height: NutriSpacing.lg),
                  Text(
                    'Việc cần làm',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: NutriSpacing.sm),
                  for (final step in latest.actionSteps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: NutriSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: NutriSpacing.sm),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: NutriSpacing.lg),
                Text(
                  'Lịch 7 ngày',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: NutriSpacing.sm),
                if (latest.days.isEmpty)
                  Text(
                    'Kế hoạch này chưa có lịch theo ngày.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final day in latest.days) _CoachPlanDayTile(day: day),
                const SizedBox(height: NutriSpacing.md),
                FilledButton.icon(
                  onPressed: _creating ? null : _create,
                  icon: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _creating ? 'Đang tạo kế hoạch...' : 'Tạo kế hoạch mới',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyCoachPlan extends StatelessWidget {
  const _EmptyCoachPlan({required this.onCreate, required this.creating});

  final VoidCallback onCreate;
  final bool creating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NutriSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 34, color: theme.colorScheme.primary),
          const SizedBox(height: NutriSpacing.sm),
          Text('Chưa có kế hoạch', style: theme.textTheme.titleMedium),
          const SizedBox(height: NutriSpacing.xs),
          Text(
            'Tạo kế hoạch tuần để xem gợi ý bữa ăn từng ngày từ AI Coach.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: NutriSpacing.md),
          FilledButton.icon(
            onPressed: creating ? null : onCreate,
            icon: creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              creating ? 'Đang tạo kế hoạch...' : 'Tạo kế hoạch tuần',
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachPlanDayTile extends StatelessWidget {
  const _CoachPlanDayTile({required this.day});

  final CoachPlanDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleParts = <String>[
      if (day.label.isNotEmpty) day.label,
      if (day.date.isNotEmpty) friendlyDate(day.date),
    ];
    final subtitleParts = <String>[
      if (day.focus.isNotEmpty) day.focus,
      if (day.targetCalories > 0) '${formatNumber(day.targetCalories)} kcal',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: NutriSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: NutriSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            NutriSpacing.md,
            0,
            NutriSpacing.md,
            NutriSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            titleParts.isEmpty
                ? 'Một ngày trong kế hoạch'
                : titleParts.join(' • '),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(subtitleParts.join(' • ')),
          children: [
            if (day.meals.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chưa có gợi ý bữa ăn.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final meal in day.meals)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restaurant_menu),
                  title: Text(meal.name),
                  subtitle: Text(
                    [
                      if (meal.time.isNotEmpty) meal.time,
                      if (meal.suggestion.isNotEmpty) meal.suggestion,
                    ].join(' • '),
                  ),
                  trailing: meal.calories > 0
                      ? Text('${formatNumber(meal.calories)} kcal')
                      : null,
                ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyProgressChart extends StatelessWidget {
  const _WeeklyProgressChart({required this.points});

  final List<JsonMap> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyState(
        title: 'Chưa có dữ liệu tuần',
        message: 'Ghi log vài bữa ăn để xem tiến độ theo tuần.',
        icon: Icons.bar_chart,
      );
    }
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '7 ngày gần đây'),
          const SizedBox(height: NutriSpacing.lg),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(asString(points[index]['day']));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: asDouble(points[i]['consumed']),
                          color: NutriColors.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: asDouble(points[i]['target'], 2000),
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPreview extends StatelessWidget {
  const _MealPreview({required this.log});

  final MealLog log;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Bữa ăn hôm nay',
            subtitle: friendlyDate(log.date),
            action: TextButton(
              onPressed: () => context.go('/tracker'),
              child: const Text('Chi tiết'),
            ),
          ),
          const SizedBox(height: NutriSpacing.sm),
          for (final meal in log.meals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: mealColor(meal.id)),
                  const SizedBox(width: NutriSpacing.sm),
                  Expanded(child: Text(meal.name)),
                  Text('${formatNumber(meal.totalCalories)} kcal'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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

  String get _dateString => localDateString(_date);

  Future<MealLog> _load() =>
      ref.read(apiClientProvider).getMealLog(_dateString);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _shiftDate(int days) {
    setState(() {
      _date = _date.add(Duration(days: days));
      _future = _load();
    });
  }

  Future<void> _replaceWith(Future<MealLog> action) async {
    try {
      final next = await action;
      if (!mounted) return;
      setState(() {
        _future = Future.value(next);
      });
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  Future<void> _addFood(String mealId) async {
    final food = await showDialog<Food>(
      context: context,
      builder: (context) => _FoodPickerDialog(api: ref.read(apiClientProvider)),
    );
    if (food == null || !mounted) return;
    await _replaceWith(
      ref.read(apiClientProvider).addMealItem(_dateString, mealId, food.id),
    );
  }

  Future<void> _addManual(String mealId) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const _ManualFoodDialog(),
    );
    if (payload == null || !mounted) return;
    await _replaceWith(
      ref.read(apiClientProvider).addMealItem(_dateString, mealId, payload),
    );
  }

  Future<void> _addPhoto(String mealId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null || !mounted) return;
    try {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      final response = await ref
          .read(apiClientProvider)
          .estimateFoodPhoto(imageDataUrl: dataUrl);
      if (!mounted) return;
      final estimate = asJsonMap(response['estimate']);
      final addable = asJsonMap(response['addableItem']);
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(asString(estimate['dishName'], 'Ước tính món ăn')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyValueLine(
                label: 'Khẩu phần',
                value: asString(estimate['portion'], '1 phần'),
              ),
              KeyValueLine(
                label: 'Calo',
                value: '${formatNumber(asDouble(estimate['calories']))} kcal',
              ),
              KeyValueLine(
                label: 'Độ tin cậy',
                value:
                    '${formatNumber(asDouble(estimate['confidence']) * 100)}%',
              ),
              if (stringList(estimate['accuracyTips']).isNotEmpty) ...[
                const SizedBox(height: NutriSpacing.sm),
                Text(stringList(estimate['accuracyTips']).first),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm vào bữa'),
            ),
          ],
        ),
      );
      if (shouldAdd != true || !mounted) return;
      await _replaceWith(
        ref.read(apiClientProvider).addMealItem(_dateString, mealId, addable),
      );
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  Future<void> _estimateCustom(String mealId) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const _CustomFoodDialog(),
    );
    if (payload == null || !mounted) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .estimateCustomFood(payload);
      if (!mounted) return;
      final addable = asJsonMap(response['addableItem']);
      final estimate = asJsonMap(response['estimate']);
      if (addable.isEmpty) {
        showSnack(
          context,
          asString(response['question'], 'Backend cần thêm thông tin món ăn.'),
        );
        return;
      }
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            asString(
              estimate['dishName'],
              payload['name']?.toString() ?? 'Món tự nấu',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyValueLine(
                label: 'Mỗi phần',
                value:
                    '${formatNumber(asDouble(asJsonMap(estimate['perServing'])['calories']))} kcal',
              ),
              KeyValueLine(
                label: 'Protein',
                value:
                    '${formatNumber(asDouble(asJsonMap(estimate['perServing'])['protein']), digits: 1)} g',
              ),
              Text(asString(estimate['disclaimer'])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      );
      if (shouldAdd != true || !mounted) return;
      await _replaceWith(
        ref.read(apiClientProvider).addMealItem(_dateString, mealId, addable),
      );
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();

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
          if (!snapshot.hasData) {
            return const NutriPage(
              children: [LoadingPanel(message: 'Đang tải meal log...')],
            );
          }
          final log = snapshot.data!;
          final summary = log.summary;
          return NutriPage(
            children: [
              NutriCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Ngày trước',
                          onPressed: () => _shiftDate(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Theo dõi bữa ăn',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(friendlyDate(_dateString)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ngày sau',
                          onPressed: () => _shiftDate(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: NutriSpacing.md),
                    ProgressLine(
                      value:
                          summary.totals.calories /
                          (summary.targets.calories == 0
                              ? 1
                              : summary.targets.calories),
                    ),
                    const SizedBox(height: NutriSpacing.sm),
                    Text(
                      '${formatNumber(summary.totals.calories)} / ${formatNumber(summary.targets.calories)} kcal',
                    ),
                  ],
                ),
              ),
              _WaterCard(
                current: log.waterGlasses,
                target: summary.targets.waterGlasses.round(),
                onChanged: (value) => _replaceWith(
                  ref.read(apiClientProvider).updateWater(_dateString, value),
                ),
              ),
              for (final meal in log.meals)
                _MealSectionCard(
                  meal: meal,
                  onAddFood: () => _addFood(meal.id),
                  onAddManual: () => _addManual(meal.id),
                  onAddPhoto: () => _addPhoto(meal.id),
                  onCustomEstimate: () => _estimateCustom(meal.id),
                  onDelete: (item) => _replaceWith(
                    ref
                        .read(apiClientProvider)
                        .deleteMealItem(_dateString, meal.id, item.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.current,
    required this.target,
    required this.onChanged,
  });

  final int current;
  final int target;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Nước uống',
            subtitle: 'Cập nhật nhanh số ly nước trong ngày.',
          ),
          const SizedBox(height: NutriSpacing.md),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: current > 0 ? () => onChanged(current - 1) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$current/$target ly',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ProgressLine(
                      value: target == 0 ? 0 : current / target,
                      color: NutriColors.teal,
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () => onChanged(current + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealSectionCard extends StatelessWidget {
  const _MealSectionCard({
    required this.meal,
    required this.onAddFood,
    required this.onAddManual,
    required this.onAddPhoto,
    required this.onCustomEstimate,
    required this.onDelete,
  });

  final MealSection meal;
  final VoidCallback onAddFood;
  final VoidCallback onAddManual;
  final VoidCallback onAddPhoto;
  final VoidCallback onCustomEstimate;
  final ValueChanged<MealItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = mealColor(meal.id);
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.restaurant, color: accent),
              ),
              const SizedBox(width: NutriSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${meal.time} • mục tiêu ${formatNumber(meal.targetKcal)} kcal',
                    ),
                  ],
                ),
              ),
              Text('${formatNumber(meal.totalCalories)} kcal'),
            ],
          ),
          const SizedBox(height: NutriSpacing.md),
          if (meal.items.isEmpty)
            const EmptyState(
              title: 'Chưa có món',
              message: 'Thêm món từ thư viện, nhập tay hoặc ước tính từ ảnh.',
              icon: Icons.no_meals_outlined,
            )
          else
            for (final item in meal.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(
                  '${item.portion} • x${formatNumber(item.quantity, digits: 1)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${formatNumber(item.calories)} kcal'),
                    IconButton(
                      tooltip: 'Xóa món',
                      onPressed: () => onDelete(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: NutriSpacing.sm),
          Wrap(
            spacing: NutriSpacing.sm,
            runSpacing: NutriSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: onAddFood,
                icon: const Icon(Icons.search),
                label: const Text('Thư viện'),
              ),
              OutlinedButton.icon(
                onPressed: onAddManual,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Nhập tay'),
              ),
              OutlinedButton.icon(
                onPressed: onCustomEstimate,
                icon: const Icon(Icons.soup_kitchen_outlined),
                label: const Text('Món tự nấu'),
              ),
              OutlinedButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Ảnh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() {
      _future = widget.api.getFoods(_search.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn món ăn'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                labelText: 'Tìm món',
                suffixIcon: IconButton(
                  onPressed: _runSearch,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: NutriSpacing.md),
            Flexible(
              child: FutureBuilder<List<Food>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorPanel(
                      error: snapshot.error!,
                      onRetry: _runSearch,
                    );
                  }
                  if (!snapshot.hasData) return const LoadingPanel();
                  final foods = snapshot.data!;
                  if (foods.isEmpty) {
                    return const EmptyState(
                      title: 'Không thấy món',
                      message: 'Thử từ khóa khác hoặc nhập tay.',
                      icon: Icons.search_off,
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text('${food.portion} • ${food.category}'),
                        trailing: Text('${formatNumber(food.calories)} kcal'),
                        onTap: () => Navigator.pop(context, food),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _ManualFoodDialog extends StatefulWidget {
  const _ManualFoodDialog();

  @override
  State<_ManualFoodDialog> createState() => _ManualFoodDialogState();
}

class _ManualFoodDialogState extends State<_ManualFoodDialog> {
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController(text: '0');
  final _carbs = TextEditingController(text: '0');
  final _fat = TextEditingController(text: '0');
  final _portion = TextEditingController(text: '1 phần');
  final _quantity = TextEditingController(text: '1');

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _portion.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập món thủ công'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên món'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calo'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            Row(
              children: [
                Expanded(child: _macroField(_protein, 'Protein')),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(child: _macroField(_carbs, 'Carbs')),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(child: _macroField(_fat, 'Fat')),
              ],
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _portion,
              decoration: const InputDecoration(labelText: 'Khẩu phần'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng'),
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
          onPressed: () => Navigator.pop(context, {
            'name': _name.text.trim().isEmpty
                ? 'Món tự nhập'
                : _name.text.trim(),
            'calories': double.tryParse(_calories.text) ?? 0,
            'protein': double.tryParse(_protein.text) ?? 0,
            'carbs': double.tryParse(_carbs.text) ?? 0,
            'fat': double.tryParse(_fat.text) ?? 0,
            'portion': _portion.text.trim().isEmpty
                ? '1 phần'
                : _portion.text.trim(),
            'quantity': double.tryParse(_quantity.text) ?? 1,
          }),
          child: const Text('Thêm'),
        ),
      ],
    );
  }

  Widget _macroField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: '$label (g)'),
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
  final _servings = TextEditingController(text: '2');
  final _method = TextEditingController(text: 'luộc/xào');
  final _rawText = TextEditingController(
    text: '200g ức gà, 100g cơm trắng, 50g rau',
  );

  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    _method.dispose();
    _rawText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ước tính món tự nấu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên món'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _servings,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số phần'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _method,
              decoration: const InputDecoration(labelText: 'Cách nấu'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _rawText,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Nguyên liệu'),
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
          onPressed: () => Navigator.pop(context, {
            'name': _name.text.trim().isEmpty
                ? 'Món tự nấu'
                : _name.text.trim(),
            'servings': int.tryParse(_servings.text) ?? 1,
            'cookingMethod': _method.text.trim(),
            'rawText': _rawText.text.trim(),
            'ingredients': <JsonMap>[],
          }),
          child: const Text('Ước tính'),
        ),
      ],
    );
  }
}

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _age = TextEditingController(text: '25');
  final _weight = TextEditingController(text: '65');
  final _height = TextEditingController(text: '168');
  final _duration = TextEditingController(text: '30');
  String _gender = 'female';
  String _activity = 'light';
  String _goal = 'maintain';
  String _exercise = 'walking';
  CalorieCalculation? _calculation;
  bool _loading = false;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _duration.dispose();
    super.dispose();
  }

  JsonMap get _payload => {
    'age': int.tryParse(_age.text) ?? 25,
    'weightKg': double.tryParse(_weight.text) ?? 65,
    'heightCm': double.tryParse(_height.text) ?? 168,
    'gender': _gender,
    'activityLevel': _activity,
    'goal': _goal,
    'exerciseType': _exercise,
    'durationMinutes': int.tryParse(_duration.text) ?? 30,
  };

  Future<void> _calculate() async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .calculateCalories(_payload);
      if (!mounted) return;
      setState(() => _calculation = result);
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      final member = await ref
          .read(apiClientProvider)
          .saveNutritionProfile(_payload);
      await ref.read(sessionControllerProvider).syncMember(member);
      if (!mounted) return;
      showSnack(context, 'Đã lưu hồ sơ dinh dưỡng.');
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(sessionControllerProvider).isLoggedIn;
    final results = _calculation?.results ?? const <String, dynamic>{};
    final macros = jsonMapList(results['macros']);

    return NutriPage(
      children: [
        const SectionHeader(
          title: 'Tính calo',
          subtitle: 'BMR, TDEE, BMI, macro và cảnh báo theo mục tiêu.',
        ),
        NutriCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _field(_age, 'Tuổi')),
                  const SizedBox(width: NutriSpacing.sm),
                  Expanded(child: _field(_weight, 'Kg')),
                  const SizedBox(width: NutriSpacing.sm),
                  Expanded(child: _field(_height, 'Cm')),
                ],
              ),
              const SizedBox(height: NutriSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                ],
                onChanged: (value) =>
                    setState(() => _gender = value ?? _gender),
              ),
              const SizedBox(height: NutriSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration: const InputDecoration(labelText: 'Mức vận động'),
                items: const [
                  DropdownMenuItem(
                    value: 'sedentary',
                    child: Text('Ít vận động'),
                  ),
                  DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                  DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                  DropdownMenuItem(value: 'active', child: Text('Năng động')),
                  DropdownMenuItem(
                    value: 'very_active',
                    child: Text('Rất năng động'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _activity = value ?? _activity),
              ),
              const SizedBox(height: NutriSpacing.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lose', label: Text('Giảm')),
                  ButtonSegment(value: 'maintain', label: Text('Giữ')),
                  ButtonSegment(value: 'gain', label: Text('Tăng')),
                ],
                selected: {_goal},
                onSelectionChanged: (values) =>
                    setState(() => _goal = values.first),
              ),
              const SizedBox(height: NutriSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _exercise,
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
                        DropdownMenuItem(value: 'swimming', child: Text('Bơi')),
                        DropdownMenuItem(
                          value: 'strength',
                          child: Text('Tập tạ'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _exercise = value ?? _exercise),
                    ),
                  ),
                  const SizedBox(width: NutriSpacing.sm),
                  Expanded(child: _field(_duration, 'Phút tập')),
                ],
              ),
              const SizedBox(height: NutriSpacing.lg),
              FilledButton.icon(
                onPressed: _loading ? null : _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Tính ngay'),
              ),
            ],
          ),
        ),
        if (_calculation != null)
          NutriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Kết quả'),
                const SizedBox(height: NutriSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 560;
                    return GridView.count(
                      crossAxisCount: wide ? 3 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: wide ? 1.4 : 4,
                      mainAxisSpacing: NutriSpacing.md,
                      crossAxisSpacing: NutriSpacing.md,
                      children: [
                        MetricCard(
                          label: 'BMR',
                          value:
                              '${formatNumber(asDouble(results['bmr']))} kcal',
                          icon: Icons.monitor_heart_outlined,
                          accent: NutriColors.blue,
                        ),
                        MetricCard(
                          label: 'TDEE',
                          value:
                              '${formatNumber(asDouble(results['tdee']))} kcal',
                          icon: Icons.bolt_outlined,
                          accent: NutriColors.amber,
                        ),
                        MetricCard(
                          label: 'Mục tiêu',
                          value:
                              '${formatNumber(asDouble(results['calorieGoal']))} kcal',
                          icon: Icons.flag_outlined,
                          accent: NutriColors.primary,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: NutriSpacing.md),
                KeyValueLine(
                  label: 'BMI',
                  value:
                      '${formatNumber(asDouble(asJsonMap(results['bmi'])['value']), digits: 1)} - ${asString(asJsonMap(results['bmi'])['label'])}',
                ),
                for (final macro in macros)
                  KeyValueLine(
                    label: asString(macro['name']),
                    value:
                        '${formatNumber(asDouble(macro['grams']))} g (${formatNumber(asDouble(macro['pct']))}%)',
                  ),
                if (stringList(results['warnings']).isNotEmpty) ...[
                  const SizedBox(height: NutriSpacing.sm),
                  for (final warning in stringList(results['warnings']))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber,
                        color: NutriColors.amber,
                      ),
                      title: Text(warning),
                    ),
                ],
                if (_calculation!.aiInsight != null) ...[
                  const SizedBox(height: NutriSpacing.sm),
                  Text(
                    asString(_calculation!.aiInsight!['summary']),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: NutriSpacing.lg),
                if (loggedIn)
                  FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu vào hồ sơ'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.go('/login?from=%2Fcalculator'),
                    icon: const Icon(Icons.login),
                    label: const Text('Đăng nhập để lưu'),
                  ),
              ],
            ),
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
}

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _search = TextEditingController();
  String _tag = 'Tất cả';
  late Future<RecipeCollection> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
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

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _generateRecipe() async {
    final member = ref.read(sessionControllerProvider).member;
    if (member == null) {
      context.go('/login?from=%2Frecipes');
      return;
    }
    if (!member.isSvip) {
      showSnack(context, 'AI recipe cá nhân hóa mở cho SVIP.');
      return;
    }
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) => const _PromptDialog(
        title: 'AI recipe cá nhân hóa',
        label: 'Bạn muốn ăn gì?',
        hint: 'Ví dụ: bữa trưa ít calo, nhiều protein, có ức gà...',
      ),
    );
    if (prompt == null || prompt.trim().isEmpty || !mounted) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .generatePersonalizedRecipe({'prompt': prompt.trim()});
      if (!mounted) return;
      if (asString(response['status']) == 'recipe') {
        final recipe = Recipe.fromJson(response['recipe']);
        await showRecipeDetails(context, recipe);
        _reload();
      } else {
        final questions = jsonMapList(
          response['questions'],
        ).map((item) => asString(item['question'])).join('\n');
        showSnack(
          context,
          questions.isEmpty ? asString(response['message']) : questions,
        );
      }
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
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
          if (!snapshot.hasData) {
            return const NutriPage(
              children: [LoadingPanel(message: 'Đang tải công thức...')],
            );
          }
          final data = snapshot.data!;
          final tags = {'Tất cả', ...data.tags};
          return NutriPage(
            children: [
              SectionHeader(
                title: 'Công thức',
                subtitle: data.access?.recipeLimit == null
                    ? 'Không giới hạn theo gói hiện tại.'
                    : 'Gói free xem ${data.access!.recipeLimit} công thức đầu tiên.',
                action: IconButton.filledTonal(
                  tooltip: 'AI recipe',
                  onPressed: _generateRecipe,
                  icon: const Icon(Icons.auto_awesome),
                ),
              ),
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _reload(),
                decoration: InputDecoration(
                  labelText: 'Tìm món, tag, nguyên liệu',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tag in tags)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tag),
                          selected: _tag == tag,
                          onSelected: (_) {
                            setState(() {
                              _tag = tag;
                              _future = _load();
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (member != null && member.isSvip)
                FutureBuilder<List<Recipe>>(
                  future: ref.read(apiClientProvider).getPersonalizedRecipes(),
                  builder: (context, saved) {
                    if (!saved.hasData || saved.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _RecipeRail(
                      title: 'Công thức AI đã lưu',
                      recipes: saved.data!,
                    );
                  },
                )
              else
                const LockedPanel(
                  title: 'AI recipe SVIP',
                  message:
                      'Mở khóa công thức cá nhân hóa theo lịch ăn và mục tiêu.',
                ),
              if (data.recipes.isEmpty)
                const EmptyState(
                  title: 'Không có công thức',
                  message: 'Thử đổi tag hoặc từ khóa tìm kiếm.',
                  icon: Icons.menu_book_outlined,
                )
              else
                for (final recipe in data.recipes) _RecipeCard(recipe: recipe),
            ],
          );
        },
      ),
    );
  }
}

class _RecipeRail extends StatelessWidget {
  const _RecipeRail({required this.title, required this.recipes});

  final String title;
  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: NutriSpacing.sm),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: NutriSpacing.sm),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return SizedBox(
                  width: 220,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showRecipeDetails(context, recipe),
                    child: NutriCard(
                      padding: const EdgeInsets.all(NutriSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${formatNumber(recipe.calories)} kcal • ${recipe.timeMinutes} phút',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      child: InkWell(
        onTap: () => showRecipeDetails(context, recipe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: NutriColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: NutriColors.primary,
                  ),
                ),
                const SizedBox(width: NutriSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recipe.timeMinutes} phút • ${formatNumber(recipe.calories)} kcal • ${recipe.servings} phần',
                      ),
                      const SizedBox(height: NutriSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in recipe.tags.take(4))
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showRecipeDetails(BuildContext context, Recipe recipe) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.94,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(NutriSpacing.page),
        children: [
          Text(recipe.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: NutriSpacing.sm),
          Wrap(
            spacing: NutriSpacing.sm,
            runSpacing: NutriSpacing.sm,
            children: [
              Chip(label: Text('${recipe.timeMinutes} phút')),
              Chip(label: Text('${formatNumber(recipe.calories)} kcal')),
              Chip(label: Text('${recipe.servings} phần')),
              for (final tag in recipe.tags) Chip(label: Text(tag)),
            ],
          ),
          if (recipe.personalizationSummary.isNotEmpty) ...[
            const SizedBox(height: NutriSpacing.md),
            NutriCard(child: Text(recipe.personalizationSummary)),
          ],
          const SizedBox(height: NutriSpacing.md),
          const SectionHeader(title: 'Nguyên liệu'),
          for (final item in recipe.ingredients)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(asString(item['name'])),
              trailing: Text(asString(item['amount'])),
            ),
          const SizedBox(height: NutriSpacing.md),
          const SectionHeader(title: 'Cách làm'),
          for (var i = 0; i < recipe.steps.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
              title: Text(recipe.steps[i]),
            ),
          if (recipe.notes.isNotEmpty) ...[
            const SizedBox(height: NutriSpacing.md),
            const SectionHeader(title: 'Ghi chú AI'),
            for (final note in recipe.notes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome),
                title: Text(note),
              ),
          ],
        ],
      ),
    ),
  );
}

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  String _billing = 'monthly';
  late Future<List<Plan>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiClientProvider).getPlans(_billing);
  }

  void _reload() {
    setState(() {
      _future = ref.read(apiClientProvider).getPlans(_billing);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plan>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) {
          return const NutriPage(
            children: [LoadingPanel(message: 'Đang tải gói...')],
          );
        }
        final plans = snapshot.data!;
        return NutriPage(
          children: [
            SectionHeader(
              title: 'Gói thành viên',
              subtitle:
                  'VIP xanh emerald, SVIP amber/orange như web NutriPath.',
              action: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('Tháng')),
                  ButtonSegment(value: 'annual', label: Text('Năm')),
                ],
                selected: {_billing},
                onSelectionChanged: (values) {
                  setState(() {
                    _billing = values.first;
                    _future = ref.read(apiClientProvider).getPlans(_billing);
                  });
                },
              ),
            ),
            for (final plan in plans) _PlanCard(plan: plan, billing: _billing),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.billing});

  final Plan plan;
  final String billing;

  @override
  Widget build(BuildContext context) {
    final isSvip = plan.id == 'svip';
    final isVip = plan.id == 'vip';
    final accent = isSvip
        ? NutriColors.amber
        : isVip
        ? NutriColors.emerald
        : NutriColors.blue;
    final price = plan.pricePreview?.total ?? plan.monthlyPrice;
    return NutriCard(
      color: accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: accent),
                ),
              ),
              TierChip(tier: plan.id),
            ],
          ),
          const SizedBox(height: NutriSpacing.sm),
          Text(plan.description),
          const SizedBox(height: NutriSpacing.md),
          Text(
            plan.id == 'free' ? 'Miễn phí' : formatVnd(price),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: NutriSpacing.md),
          for (final feature in plan.features)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                asBool(feature['included'])
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                color: asBool(feature['included'])
                    ? accent
                    : Theme.of(context).disabledColor,
              ),
              title: Text(asString(feature['label'])),
            ),
          const SizedBox(height: NutriSpacing.md),
          if (plan.id != 'free')
            FilledButton.icon(
              onPressed: () =>
                  context.go('/checkout?plan=${plan.id}&billing=$billing'),
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Bắt đầu miễn phí'),
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

  final String initialPlanId;
  final String initialBilling;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _discount = TextEditingController();
  late String _planId;
  late String _billing;
  String _method = 'card';
  int _trialDays = 0;
  late Future<CheckoutQuote> _future;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _planId = widget.initialPlanId == 'svip' ? 'svip' : 'vip';
    _billing = widget.initialBilling == 'annual' ? 'annual' : 'monthly';
    _future = _quote();
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
          planId: _planId,
          billing: _billing,
          discountCode: _discount.text.trim(),
          trialDays: _trialDays,
        );
  }

  void _reload() {
    setState(() {
      _future = _quote();
    });
  }

  Future<void> _pay() async {
    final member = ref.read(sessionControllerProvider).member;
    if (member == null) return;
    setState(() => _paying = true);
    try {
      final (_, updatedMember) = await ref
          .read(apiClientProvider)
          .createPayment({
            'memberId': member.id,
            'planId': _planId,
            'billing': _billing,
            'paymentMethod': _method,
            'discountCode': _discount.text.trim(),
            'trialDays': _trialDays,
          });
      await ref.read(sessionControllerProvider).syncMember(updatedMember);
      if (!mounted) return;
      showSnack(
        context,
        'Gói ${updatedMember.tier.toUpperCase()} đã được kích hoạt.',
      );
      context.go('/profile');
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();

    return FutureBuilder<CheckoutQuote>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) {
          return const NutriPage(
            children: [LoadingPanel(message: 'Đang tính đơn hàng...')],
          );
        }
        final quote = snapshot.data!;
        return NutriPage(
          children: [
            const SectionHeader(
              title: 'Checkout',
              subtitle: 'Payment demo theo backend, không lưu thông tin thẻ.',
            ),
            NutriCard(
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'vip', label: Text('VIP')),
                      ButtonSegment(value: 'svip', label: Text('SVIP')),
                    ],
                    selected: {_planId},
                    onSelectionChanged: (values) {
                      setState(() {
                        _planId = values.first;
                        _future = _quote();
                      });
                    },
                  ),
                  const SizedBox(height: NutriSpacing.md),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'monthly', label: Text('Tháng')),
                      ButtonSegment(value: 'annual', label: Text('Năm')),
                    ],
                    selected: {_billing},
                    onSelectionChanged: (values) {
                      setState(() {
                        _billing = values.first;
                        _future = _quote();
                      });
                    },
                  ),
                  const SizedBox(height: NutriSpacing.md),
                  TextField(
                    controller: _discount,
                    decoration: InputDecoration(
                      labelText: 'Mã giảm giá',
                      suffixIcon: IconButton(
                        onPressed: _reload,
                        icon: const Icon(Icons.local_offer_outlined),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _trialDays > 0,
                    title: const Text('Kích hoạt dùng thử 7 ngày'),
                    onChanged: (value) {
                      setState(() {
                        _trialDays = value ? 7 : 0;
                        _future = _quote();
                      });
                    },
                  ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: quote.planName.isEmpty
                        ? _planId.toUpperCase()
                        : quote.planName,
                  ),
                  const SizedBox(height: NutriSpacing.md),
                  KeyValueLine(
                    label: 'Tạm tính',
                    value: formatVnd(quote.subtotal),
                  ),
                  KeyValueLine(label: 'VAT', value: formatVnd(quote.vat)),
                  KeyValueLine(
                    label: 'Giảm giá',
                    value: '-${formatVnd(quote.discountAmount)}',
                  ),
                  const Divider(),
                  KeyValueLine(label: 'Tổng', value: formatVnd(quote.total)),
                  const SizedBox(height: NutriSpacing.md),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'card', label: Text('Card')),
                      ButtonSegment(value: 'momo', label: Text('Momo')),
                      ButtonSegment(value: 'zalopay', label: Text('ZaloPay')),
                      ButtonSegment(value: 'bank', label: Text('Bank')),
                    ],
                    selected: {_method},
                    onSelectionChanged: (values) =>
                        setState(() => _method = values.first),
                  ),
                  const SizedBox(height: NutriSpacing.lg),
                  FilledButton.icon(
                    onPressed: _paying ? null : _pay,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(
                      _trialDays > 0 ? 'Kích hoạt trial' : 'Thanh toán demo',
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
        maxLines: 6,
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<_ProfileBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileBundle> _load() async {
    final api = ref.read(apiClientProvider);
    final profile = await api.getProfile();
    final notifications = await api.getNotifications(limit: 10);
    return _ProfileBundle(profile: profile, notifications: notifications);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _editProfile(Member member) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => _ProfileEditDialog(member: member),
    );
    if (payload == null || !mounted) return;
    try {
      final updated = await ref
          .read(apiClientProvider)
          .updateMemberProfile(payload);
      await ref.read(sessionControllerProvider).syncMember(updated);
      if (!mounted) return;
      showSnack(context, 'Đã cập nhật hồ sơ.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  Future<void> _editBodyProfile(Member member) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => _BodyProfileDialog(member: member),
    );
    if (payload == null || !mounted) return;
    try {
      final updated = await ref
          .read(apiClientProvider)
          .saveNutritionProfile(payload);
      await ref.read(sessionControllerProvider).syncMember(updated);
      if (!mounted) return;
      showSnack(context, 'Đã cập nhật dữ liệu cơ thể và mục tiêu dinh dưỡng.');
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(apiClientProvider).markAllNotificationsRead();
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final member = session.member;
    if (member == null) return const LoginPrompt();

    return FutureBuilder<_ProfileBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) {
          return const NutriPage(
            children: [LoadingPanel(message: 'Đang tải hồ sơ...')],
          );
        }
        final profile = snapshot.data!.profile;
        final current = Member.fromJson(profile['member']);
        final plan = asJsonMap(profile['plan']);
        final benefits = jsonMapList(profile['benefits']);
        final payments = jsonMapList(
          profile['billingHistory'],
        ).map(Payment.fromJson).toList();
        return NutriPage(
          children: [
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(
                          current.initials,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: NutriSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(current.email),
                          ],
                        ),
                      ),
                      TierChip(tier: current.tier),
                    ],
                  ),
                  const SizedBox(height: NutriSpacing.md),
                  KeyValueLine(
                    label: 'Calo mục tiêu',
                    value: '${current.calorieTarget} kcal',
                  ),
                  KeyValueLine(
                    label: 'Nước mục tiêu',
                    value: '${current.waterTargetGlasses} ly',
                  ),
                  KeyValueLine(label: 'Vai trò', value: current.role),
                  const SizedBox(height: NutriSpacing.md),
                  Wrap(
                    spacing: NutriSpacing.sm,
                    runSpacing: NutriSpacing.sm,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _editProfile(current),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sửa hồ sơ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _editBodyProfile(current),
                        icon: const Icon(Icons.monitor_weight_outlined),
                        label: const Text('Dữ liệu cơ thể'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/pricing'),
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: const Text('Gói hội viên'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(sessionControllerProvider).logout();
                          if (!context.mounted) return;
                          context.go('/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Đăng xuất'),
                      ),
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
                    title: 'Dữ liệu cơ thể',
                    subtitle:
                        'Lưu qua endpoint nutrition-profile để backend tính BMR, TDEE, BMI và macro.',
                    action: IconButton.filledTonal(
                      tooltip: 'Cập nhật dữ liệu cơ thể',
                      onPressed: () => _editBodyProfile(current),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: NutriSpacing.sm),
                  KeyValueLine(
                    label: 'Tuổi',
                    value: current.age == null ? 'Chưa nhập' : '${current.age}',
                    icon: Icons.cake_outlined,
                  ),
                  KeyValueLine(
                    label: 'Giới tính',
                    value: _genderLabel(current.gender),
                    icon: Icons.wc_outlined,
                  ),
                  KeyValueLine(
                    label: 'Cân nặng',
                    value: current.weightKg == null
                        ? 'Chưa nhập'
                        : '${formatNumber(current.weightKg!, digits: 1)} kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  KeyValueLine(
                    label: 'Chiều cao',
                    value: current.heightCm == null
                        ? 'Chưa nhập'
                        : '${formatNumber(current.heightCm!, digits: 1)} cm',
                    icon: Icons.height,
                  ),
                  KeyValueLine(
                    label: 'Vận động',
                    value: _activityLabel(current.activityLevel),
                    icon: Icons.directions_run,
                  ),
                  KeyValueLine(
                    label: 'Mục tiêu',
                    value: _goalLabel(current.goal),
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: NutriSpacing.md),
                  FilledButton.icon(
                    onPressed: () => _editBodyProfile(current),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Cập nhật & tính lại mục tiêu'),
                  ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Subscription',
                    subtitle: plan.isEmpty
                        ? 'Gói hiện tại: ${current.tier.toUpperCase()}'
                        : asString(plan['name']),
                  ),
                  const SizedBox(height: NutriSpacing.sm),
                  if (current.subscription != null) ...[
                    KeyValueLine(
                      label: 'Trạng thái',
                      value: current.subscription!.status,
                    ),
                    KeyValueLine(
                      label: 'Billing',
                      value: current.subscription!.billing,
                    ),
                    KeyValueLine(
                      label: 'Gia hạn',
                      value: current.subscription!.renewsAt ?? 'Chưa có',
                    ),
                  ],
                  if (benefits.isNotEmpty) ...[
                    const SizedBox(height: NutriSpacing.sm),
                    for (final benefit in benefits.take(6))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          asBool(benefit['included'])
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                        ),
                        title: Text(asString(benefit['label'])),
                      ),
                  ],
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
                      onPressed: _markAllRead,
                      child: const Text('Đọc tất cả'),
                    ),
                  ),
                  const SizedBox(height: NutriSpacing.sm),
                  if (snapshot.data!.notifications.isEmpty)
                    const Text('Không có thông báo mới.')
                  else
                    for (final item in snapshot.data!.notifications)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          item.readAt == null
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_none,
                          color: item.priority == 'high'
                              ? NutriColors.amber
                              : null,
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.text),
                      ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Lịch sử thanh toán'),
                  const SizedBox(height: NutriSpacing.sm),
                  if (payments.isEmpty)
                    const Text('Chưa có thanh toán.')
                  else
                    for (final payment in payments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(payment.invoice),
                        subtitle: Text(
                          '${payment.planId.toUpperCase()} • ${payment.status}',
                        ),
                        trailing: Text(formatVnd(payment.amount)),
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

class _ProfileBundle {
  const _ProfileBundle({required this.profile, required this.notifications});

  final JsonMap profile;
  final List<AppNotification> notifications;
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.member});

  final Member member;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
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
    return AlertDialog(
      title: const Text('Sửa hồ sơ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calo mục tiêu'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _water,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ly nước mục tiêu'),
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
          onPressed: () => Navigator.pop(context, {
            'name': _name.text.trim(),
            'email': _email.text.trim(),
            'calorieTarget':
                int.tryParse(_calories.text) ?? widget.member.calorieTarget,
            'waterTargetGlasses':
                int.tryParse(_water.text) ?? widget.member.waterTargetGlasses,
          }),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _BodyProfileDialog extends StatefulWidget {
  const _BodyProfileDialog({required this.member});

  final Member member;

  @override
  State<_BodyProfileDialog> createState() => _BodyProfileDialogState();
}

class _BodyProfileDialogState extends State<_BodyProfileDialog> {
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _duration;
  late String _gender;
  late String _activityLevel;
  late String _goal;
  late String _exerciseType;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _age = TextEditingController(text: '${member.age ?? 25}');
    _weight = TextEditingController(text: '${member.weightKg ?? 65}');
    _height = TextEditingController(text: '${member.heightCm ?? 168}');
    _duration = TextEditingController(text: '30');
    _gender = member.gender == 'male' ? 'male' : 'female';
    _activityLevel = _validActivity(member.activityLevel);
    _goal = _validGoal(member.goal);
    _exerciseType = 'walking';
  }

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _duration.dispose();
    super.dispose();
  }

  JsonMap _payload() => {
    'age': int.tryParse(_age.text) ?? 25,
    'weightKg': double.tryParse(_weight.text) ?? 65,
    'heightCm': double.tryParse(_height.text) ?? 168,
    'gender': _gender,
    'activityLevel': _activityLevel,
    'goal': _goal,
    'exerciseType': _exerciseType,
    'durationMinutes': int.tryParse(_duration.text) ?? 30,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dữ liệu cơ thể'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _numberField(_age, 'Tuổi')),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(child: _numberField(_weight, 'Cân nặng kg')),
              ],
            ),
            const SizedBox(height: NutriSpacing.sm),
            Row(
              children: [
                Expanded(child: _numberField(_height, 'Chiều cao cm')),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(child: _numberField(_duration, 'Phút tập')),
              ],
            ),
            const SizedBox(height: NutriSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                DropdownMenuItem(value: 'male', child: Text('Nam')),
              ],
              onChanged: (value) {
                setState(() {
                  _gender = value ?? _gender;
                });
              },
            ),
            const SizedBox(height: NutriSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(labelText: 'Mức vận động'),
              items: const [
                DropdownMenuItem(
                  value: 'sedentary',
                  child: Text('Ít vận động'),
                ),
                DropdownMenuItem(value: 'light', child: Text('Nhẹ')),
                DropdownMenuItem(value: 'moderate', child: Text('Vừa')),
                DropdownMenuItem(value: 'active', child: Text('Năng động')),
                DropdownMenuItem(
                  value: 'very_active',
                  child: Text('Rất năng động'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _activityLevel = value ?? _activityLevel;
                });
              },
            ),
            const SizedBox(height: NutriSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _exerciseType,
              decoration: const InputDecoration(labelText: 'Bài tập gần nhất'),
              items: const [
                DropdownMenuItem(value: 'walking', child: Text('Đi bộ')),
                DropdownMenuItem(value: 'running', child: Text('Chạy bộ')),
                DropdownMenuItem(value: 'cycling', child: Text('Đạp xe')),
                DropdownMenuItem(value: 'swimming', child: Text('Bơi')),
                DropdownMenuItem(value: 'strength', child: Text('Tập tạ')),
              ],
              onChanged: (value) {
                setState(() {
                  _exerciseType = value ?? _exerciseType;
                });
              },
            ),
            const SizedBox(height: NutriSpacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'lose', label: Text('Giảm')),
                ButtonSegment(value: 'maintain', label: Text('Giữ')),
                ButtonSegment(value: 'gain', label: Text('Tăng')),
              ],
              selected: {_goal},
              onSelectionChanged: (values) {
                setState(() {
                  _goal = values.first;
                });
              },
            ),
            const SizedBox(height: NutriSpacing.sm),
            Text(
              'Backend sẽ tính lại calorieTarget, macroTargets, BMI và lưu nutritionProfile.',
              style: Theme.of(context).textTheme.bodySmall,
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
          onPressed: () => Navigator.pop(context, _payload()),
          child: const Text('Lưu & tính lại'),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

String _validActivity(String? value) {
  const allowed = {'sedentary', 'light', 'moderate', 'active', 'very_active'};
  return allowed.contains(value) ? value! : 'light';
}

String _validGoal(String? value) {
  const allowed = {'lose', 'maintain', 'gain'};
  return allowed.contains(value) ? value! : 'maintain';
}

String _genderLabel(String? value) {
  return switch (value) {
    'male' => 'Nam',
    'female' => 'Nữ',
    _ => 'Chưa nhập',
  };
}

String _activityLabel(String? value) {
  return switch (value) {
    'sedentary' => 'Ít vận động',
    'light' => 'Nhẹ',
    'moderate' => 'Vừa',
    'active' => 'Năng động',
    'very_active' => 'Rất năng động',
    _ => 'Chưa nhập',
  };
}

String _goalLabel(String? value) {
  return switch (value) {
    'lose' => 'Giảm cân',
    'maintain' => 'Giữ cân',
    'gain' => 'Tăng cân',
    _ => 'Chưa nhập',
  };
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 7;
  late Future<NutritionReport> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiClientProvider).getNutritionReport(days: _days);
  }

  void _reload() {
    setState(() {
      _future = ref.read(apiClientProvider).getNutritionReport(days: _days);
    });
  }

  Future<void> _export() async {
    final member = ref.read(sessionControllerProvider).member;
    if (member == null || !member.canExportReports) {
      showSnack(context, 'Export báo cáo chỉ mở cho SVIP.');
      return;
    }
    try {
      final export = await ref
          .read(apiClientProvider)
          .exportNutritionReport(days: _days);
      final content = asString(export['content']);
      await Clipboard.setData(ClipboardData(text: content));
      await SharePlus.instance.share(
        ShareParams(
          text: content,
          subject: asString(export['filename'], 'nutripath-report.csv'),
        ),
      );
      if (!mounted) return;
      showSnack(context, 'Đã copy và mở share sheet cho CSV.');
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();

    return FutureBuilder<NutritionReport>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) {
          return const NutriPage(
            children: [LoadingPanel(message: 'Đang tải báo cáo...')],
          );
        }
        final report = snapshot.data!;
        return NutriPage(
          children: [
            SectionHeader(
              title: 'Báo cáo dinh dưỡng',
              subtitle: 'Tổng hợp ${asInt(report.range['days'], _days)} ngày.',
              action: IconButton.filledTonal(
                tooltip: 'Export CSV',
                onPressed: _export,
                icon: const Icon(Icons.ios_share),
              ),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 ngày')),
                ButtonSegment(value: 30, label: Text('30')),
                ButtonSegment(value: 90, label: Text('90')),
              ],
              selected: {_days},
              onSelectionChanged: (values) {
                setState(() {
                  _days = values.first;
                  _future = ref
                      .read(apiClientProvider)
                      .getNutritionReport(days: _days);
                });
              },
            ),
            if (!member.canExportReports)
              const LockedPanel(
                title: 'Export CSV dành cho SVIP',
                message:
                    'Bạn vẫn xem được báo cáo giới hạn theo gói, nhưng export cần SVIP.',
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 560;
                return GridView.count(
                  crossAxisCount: wide ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: wide ? 1.5 : 4,
                  mainAxisSpacing: NutriSpacing.md,
                  crossAxisSpacing: NutriSpacing.md,
                  children: [
                    MetricCard(
                      label: 'Calo TB',
                      value:
                          '${formatNumber(asDouble(report.averages['calories']))} kcal',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    MetricCard(
                      label: 'Tracked',
                      value:
                          '${formatNumber(asDouble(report.adherence['trackedPct']))}%',
                      icon: Icons.fact_check_outlined,
                      accent: NutriColors.blue,
                    ),
                    MetricCard(
                      label: 'Đủ nước',
                      value:
                          '${formatNumber(asDouble(report.adherence['waterDonePct']))}%',
                      icon: Icons.water_drop_outlined,
                      accent: NutriColors.teal,
                    ),
                  ],
                );
              },
            ),
            _DailyReportChart(days: report.daily),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Insight'),
                  const SizedBox(height: NutriSpacing.sm),
                  for (final insight in report.insights)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.insights_outlined),
                      title: Text(insight),
                    ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Top foods'),
                  const SizedBox(height: NutriSpacing.sm),
                  for (final food in report.topFoods.take(8))
                    KeyValueLine(
                      label: asString(food['name']),
                      value: '${formatNumber(asDouble(food['calories']))} kcal',
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

class _DailyReportChart extends StatelessWidget {
  const _DailyReportChart({required this.days});

  final List<JsonMap> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const EmptyState(
        title: 'Chưa có dữ liệu',
        message: 'Log bữa ăn để có biểu đồ báo cáo.',
        icon: Icons.show_chart,
      );
    }
    return NutriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Calo theo ngày'),
          const SizedBox(height: NutriSpacing.md),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < days.length; i++)
                        FlSpot(i.toDouble(), asDouble(days[i]['calories'])),
                    ],
                    color: NutriColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: NutriColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showChatSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const ChatSheet(),
  );
}

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({super.key});

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {
  final _input = TextEditingController();
  List<ChatMessage> _messages = const [];
  List<String> _quickReplies = const [];
  String _mode = 'assistant';
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final messages = await api.getChatHistory();
      final replies = await api.getQuickReplies();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _quickReplies = replies;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(context, readableError(error));
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    final member = ref.read(sessionControllerProvider).member;
    if (_mode == 'coach' && !(member?.canUseCoach ?? false)) {
      showSnack(context, 'Coach mode chỉ mở cho SVIP.');
      return;
    }
    setState(() => _sending = true);
    _input.clear();
    try {
      final response = await ref
          .read(apiClientProvider)
          .sendChatMessage(text, mode: _mode);
      final messages = jsonMapList(
        response['messages'],
      ).map(ChatMessage.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, ...messages];
        _quickReplies = stringList(response['quickReplies']);
      });
      final updated = response['member'];
      if (updated != null) {
        await ref
            .read(sessionControllerProvider)
            .syncMember(Member.fromJson(updated));
      }
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(sessionControllerProvider).member;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: SectionHeader(
                      title: 'NutriBot',
                      subtitle: 'Assistant dinh dưỡng an toàn theo backend.',
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'assistant',
                        icon: Icon(Icons.chat_bubble_outline),
                      ),
                      ButtonSegment(
                        value: 'coach',
                        icon: Icon(Icons.workspace_premium),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (values) =>
                        setState(() => _mode = values.first),
                  ),
                ],
              ),
            ),
            if (_mode == 'coach' && !(member?.canUseCoach ?? false))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LockedPanel(
                  title: 'Coach mode SVIP',
                  message: 'Chuyển về assistant thường hoặc nâng cấp SVIP.',
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message.sender == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: isUser
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_quickReplies.isNotEmpty)
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickReplies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(_quickReplies[index]),
                    onPressed: () => _send(_quickReplies[index]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nhắn NutriBot',
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: NutriSpacing.sm),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(sessionControllerProvider).member;
    if (member == null) return const LoginPrompt();
    if (!member.isAdmin) {
      return const NutriPage(
        children: [
          LockedPanel(
            title: 'Admin only',
            message: 'Tài khoản hiện tại không có quyền truy cập admin.',
          ),
        ],
      );
    }
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Content'),
              Tab(text: 'Analytics'),
              Tab(text: 'AI'),
              Tab(text: 'Security'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AdminOverviewTab(api: ref.read(apiClientProvider)),
                _AdminUsersTab(api: ref.read(apiClientProvider)),
                _AdminContentTab(api: ref.read(apiClientProvider)),
                _AdminAnalyticsTab(api: ref.read(apiClientProvider)),
                _AdminAiTab(api: ref.read(apiClientProvider)),
                _AdminSecurityTab(api: ref.read(apiClientProvider)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab({required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminOverview>(
      future: api.getAdminOverview(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(children: [ErrorPanel(error: snapshot.error!)]);
        }
        if (!snapshot.hasData) {
          return const NutriPage(children: [LoadingPanel()]);
        }
        final overview = snapshot.data!;
        return NutriPage(
          bottomPadding: 24,
          children: [
            for (final kpi in overview.kpis)
              MetricCard(
                label: asString(kpi['label']),
                value: asString(kpi['value']),
                caption: asString(kpi['change']),
                icon: Icons.trending_up,
              ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Người dùng gần đây'),
                  for (final user in overview.recentUsers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(asString(user['initials'], 'U')),
                      ),
                      title: Text(asString(user['name'])),
                      subtitle: Text(asString(user['email'])),
                      trailing: Text(asString(user['plan'])),
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

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab({required this.api});

  final ApiClient api;

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  final _search = TextEditingController();
  late Future<JsonMap> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAdminUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(
      () => _future = widget.api.getAdminUsers(search: _search.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NutriPage(
      bottomPadding: 24,
      children: [
        TextField(
          controller: _search,
          onSubmitted: (_) => _reload(),
          decoration: InputDecoration(
            labelText: 'Tìm user',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        FutureBuilder<JsonMap>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorPanel(error: snapshot.error!, onRetry: _reload);
            }
            if (!snapshot.hasData) return const LoadingPanel();
            final users = embeddedList(snapshot.data!, 'users');
            return NutriCard(
              child: Column(
                children: [
                  for (final user in users)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(asString(user['initials'], 'U')),
                      ),
                      title: Text(asString(user['name'])),
                      subtitle: Text(
                        '${asString(user['email'])} • ${asString(user['role'])}',
                      ),
                      trailing: Text(asString(user['status'])),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AdminContentTab extends StatefulWidget {
  const _AdminContentTab({required this.api});

  final ApiClient api;

  @override
  State<_AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends State<_AdminContentTab> {
  late Future<JsonMap> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAdminContent();
  }

  void _reload() {
    setState(() {
      _future = widget.api.getAdminContent();
    });
  }

  Future<void> _createFood() async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => const _FoodEditorDialog(),
    );
    if (payload == null || !mounted) return;
    try {
      await widget.api.createFood(payload);
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  Future<void> _editFood(Food food) async {
    final payload = await showDialog<JsonMap>(
      context: context,
      builder: (context) => _FoodEditorDialog(food: food),
    );
    if (payload == null || !mounted) return;
    try {
      await widget.api.updateFood(food.id, payload);
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  Future<void> _deleteFood(Food food) async {
    try {
      await widget.api.deleteFood(food.id);
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JsonMap>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [ErrorPanel(error: snapshot.error!, onRetry: _reload)],
          );
        }
        if (!snapshot.hasData) {
          return const NutriPage(children: [LoadingPanel()]);
        }
        final foods = jsonMapList(
          snapshot.data!['foods'],
        ).map(Food.fromJson).toList();
        final recipes = jsonMapList(
          snapshot.data!['recipes'],
        ).map(Recipe.fromJson).toList();
        return NutriPage(
          bottomPadding: 24,
          children: [
            SectionHeader(
              title: 'Foods CRUD',
              action: IconButton.filled(
                onPressed: _createFood,
                icon: const Icon(Icons.add),
              ),
            ),
            NutriCard(
              child: Column(
                children: [
                  for (final food in foods.take(20))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: Text('${food.category} • ${food.portion}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${formatNumber(food.calories)} kcal'),
                          IconButton(
                            onPressed: () => _editFood(food),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _deleteFood(food),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Recipes (${recipes.length})'),
                  for (final recipe in recipes.take(12))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(recipe.name),
                      subtitle: Text(recipe.tags.join(', ')),
                      trailing: Text('${formatNumber(recipe.calories)} kcal'),
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

class _FoodEditorDialog extends StatefulWidget {
  const _FoodEditorDialog({this.food});

  final Food? food;

  @override
  State<_FoodEditorDialog> createState() => _FoodEditorDialogState();
}

class _FoodEditorDialogState extends State<_FoodEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _portion;

  @override
  void initState() {
    super.initState();
    final food = widget.food;
    _name = TextEditingController(text: food?.name ?? '');
    _category = TextEditingController(text: food?.category ?? '');
    _calories = TextEditingController(
      text: food == null ? '' : '${food.calories}',
    );
    _protein = TextEditingController(
      text: food == null ? '0' : '${food.protein}',
    );
    _carbs = TextEditingController(text: food == null ? '0' : '${food.carbs}');
    _fat = TextEditingController(text: food == null ? '0' : '${food.fat}');
    _portion = TextEditingController(text: food?.portion ?? '100g');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _portion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.food == null ? 'Tạo food' : 'Sửa food'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _portion,
              decoration: const InputDecoration(labelText: 'Portion'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            TextField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories'),
            ),
            const SizedBox(height: NutriSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _protein,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Protein'),
                  ),
                ),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _carbs,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Carbs'),
                  ),
                ),
                const SizedBox(width: NutriSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _fat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fat'),
                  ),
                ),
              ],
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
          onPressed: () => Navigator.pop(context, {
            'name': _name.text.trim(),
            'category': _category.text.trim(),
            'portion': _portion.text.trim(),
            'calories': double.tryParse(_calories.text) ?? 0,
            'protein': double.tryParse(_protein.text) ?? 0,
            'carbs': double.tryParse(_carbs.text) ?? 0,
            'fat': double.tryParse(_fat.text) ?? 0,
          }),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _AdminAnalyticsTab extends StatelessWidget {
  const _AdminAnalyticsTab({required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JsonMap>(
      future: api.getAdminAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(children: [ErrorPanel(error: snapshot.error!)]);
        }
        if (!snapshot.hasData) {
          return const NutriPage(children: [LoadingPanel()]);
        }
        final daily = jsonMapList(snapshot.data!['dailyMeals']);
        final top = jsonMapList(snapshot.data!['topDishes']);
        return NutriPage(
          bottomPadding: 24,
          children: [
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Meals 7 ngày'),
                  const SizedBox(height: NutriSpacing.md),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        barGroups: [
                          for (var i = 0; i < daily.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: asDouble(daily[i]['meals']),
                                  color: NutriColors.primary,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Top dishes'),
                  for (final dish in top)
                    KeyValueLine(
                      label:
                          '#${asInt(dish['rank'])} ${asString(dish['dish'])}',
                      value: '${asInt(dish['searches'])} lượt',
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

class _AdminAiTab extends StatefulWidget {
  const _AdminAiTab({required this.api});

  final ApiClient api;

  @override
  State<_AdminAiTab> createState() => _AdminAiTabState();
}

class _AdminAiTabState extends State<_AdminAiTab> {
  late Future<JsonMap> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getAdminAiSettings();
  }

  Future<void> _toggle(String key, bool value) async {
    try {
      await widget.api.updateAdminAiSettings({key: value});
      if (!mounted) return;
      setState(() {
        _future = widget.api.getAdminAiSettings();
      });
    } catch (error) {
      if (!mounted) return;
      showSnack(context, readableError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JsonMap>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(children: [ErrorPanel(error: snapshot.error!)]);
        }
        if (!snapshot.hasData) {
          return const NutriPage(children: [LoadingPanel()]);
        }
        final settings = asJsonMap(snapshot.data!['settings']);
        return NutriPage(
          bottomPadding: 24,
          children: [
            NutriCard(
              child: Column(
                children: [
                  KeyValueLine(
                    label: 'Model',
                    value: asString(settings['model']),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: asBool(settings['autoPortionRecommendation']),
                    title: const Text('Auto portion recommendation'),
                    onChanged: (value) =>
                        _toggle('autoPortionRecommendation', value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: asBool(settings['smartMealSuggestions']),
                    title: const Text('Smart meal suggestions'),
                    onChanged: (value) =>
                        _toggle('smartMealSuggestions', value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: asBool(settings['nutritionValidation']),
                    title: const Text('Nutrition validation'),
                    onChanged: (value) => _toggle('nutritionValidation', value),
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

class _AdminSecurityTab extends StatelessWidget {
  const _AdminSecurityTab({required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JsonMap>>(
      future: Future.wait([api.getAdminSecurity(), api.getAdminAiSafetyLogs()]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(children: [ErrorPanel(error: snapshot.error!)]);
        }
        if (!snapshot.hasData) {
          return const NutriPage(children: [LoadingPanel()]);
        }
        final security = asJsonMap(snapshot.data![0]['security']);
        final logs = jsonMapList(snapshot.data![1]['logs']);
        final activity = jsonMapList(security['loginActivity']);
        return NutriPage(
          bottomPadding: 24,
          children: [
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Security'),
                  KeyValueLine(
                    label: 'Two-factor',
                    value: asBool(security['twoFactorEnabled']) ? 'Bật' : 'Tắt',
                  ),
                  const SizedBox(height: NutriSpacing.sm),
                  for (final item in activity)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.devices_outlined),
                      title: Text(asString(item['device'])),
                      subtitle: Text(
                        '${asString(item['ip'])} • ${asString(item['location'])}',
                      ),
                      trailing: Text(asString(item['status'])),
                    ),
                ],
              ),
            ),
            NutriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'AI safety logs'),
                  if (logs.isEmpty)
                    const Text('Không có log nguy hiểm.')
                  else
                    for (final log in logs.take(20))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.shield_outlined),
                        title: Text(asString(log['reason'], 'Log')),
                        subtitle: Text(asString(log['prompt'])),
                        trailing: Text(asString(log['time'])),
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
