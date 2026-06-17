import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/calories_line_chart.dart';

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

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NutritionReport>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return NutriPage(
            children: [
              ErrorPanel(error: snapshot.error!, onRetry: _reload)
            ],
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
                    accent: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Tuân thủ',
                    value: '${asInt(report.adherence['onTargetPct'])}%',
                    caption: 'mục tiêu calo',
                    icon: Icons.verified_outlined,
                    accent: AppColors.emerald,
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
                    child: CaloriesLineChart(daily: report.daily),
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
      if (!context.mounted) return;
      showSnack(context, readableError(e));
    }
  }
}
