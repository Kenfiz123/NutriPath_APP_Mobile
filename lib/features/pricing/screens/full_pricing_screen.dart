import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_services.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/full_plan_card.dart';

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

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PricingBundle>(
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
              FullPlanCard(plan: plan, billing: _billing),
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
