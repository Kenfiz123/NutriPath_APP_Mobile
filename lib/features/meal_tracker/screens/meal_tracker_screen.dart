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
  Future<MealLog>? _future;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  Future<MealLog> _load() =>
      ref.read(apiClientProvider).getMealLog(localDateString(_date));

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _applyLog(MealLog log) {
    setState(() {
      _future = Future.value(log);
    });
  }

  void _shift(int d) => setState(() {
        _date = _date.add(Duration(days: d));
        _future = null;
      });

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.initialized) return const LoadingPanel();
    if (!session.isLoggedIn) return const LoginPrompt();
    final future = _future ??= _load();

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<MealLog>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NutriPage(
              children: [
                ErrorPanel(error: snapshot.error!, onRetry: _reload)
              ],
            );
          }
          if (!snapshot.hasData) return const LoadingPanel();
          final log = snapshot.data!;

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
        },
      ),
    );
  }
}
