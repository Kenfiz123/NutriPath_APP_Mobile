import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/date_navigator.dart';
import '../widgets/meal_section_widget.dart';
import '../widgets/water_tracker.dart';
import '../widgets/workout_tracker.dart';

class MealTrackerScreen extends ConsumerStatefulWidget {
  const MealTrackerScreen({super.key});

  @override
  ConsumerState<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends ConsumerState<MealTrackerScreen> {
  late DateTime _date;
  MealLog? _localLog;
  DateTime? _lastLoggedDate;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  void _reload() {
    ref.invalidate(mealLogProvider(localDateString(_date)));
    setState(() {
      _localLog = null;
    });
  }

  void _applyLog(MealLog log) {
    setState(() {
      _localLog = log;
    });
    // Invalidate caches to trigger background sync for meal tracker and dashboard
    ref.invalidate(mealLogProvider(localDateString(_date)));
    ref.invalidate(dashboardDataProvider(localDateString(_date)));
  }

  void _shift(int d) {
    setState(() {
      _date = _date.add(Duration(days: d));
      _localLog = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.initialized) return const LoadingPanel();
    if (!session.isLoggedIn) return const LoginPrompt();

    final dateStr = localDateString(_date);
    final asyncLog = ref.watch(mealLogProvider(dateStr));

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: asyncLog.when(
        loading: () => _localLog != null && _lastLoggedDate == _date
            ? _buildContent(_localLog!)
            : const LoadingPanel(),
        error: (err, stack) => NutriPage(
          children: [
            ErrorPanel(
              error: err,
              onRetry: () => _reload(),
            ),
          ],
        ),
        data: (log) {
          if (_localLog == null || _lastLoggedDate != _date) {
            _localLog = log;
            _lastLoggedDate = _date;
          }
          return _buildContent(_localLog!);
        },
      ),
    );
  }

  Widget _buildContent(MealLog log) {
    return NutriPage(
      children: [
        DateNavigator(
          date: _date,
          onPrev: () => _shift(-1),
          onNext: () => _shift(1),
        ),
        WaterTracker(log: log, onUpdate: _applyLog),
        WorkoutTracker(log: log, onUpdate: _reload),
        for (final m in log.meals)
          MealSectionWidget(meal: m, date: _date, onUpdate: _applyLog),
      ],
    );
  }
}
