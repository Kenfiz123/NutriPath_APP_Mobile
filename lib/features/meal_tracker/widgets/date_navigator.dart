import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets.dart';

class DateNavigator extends StatelessWidget {
  const DateNavigator({
    required this.date,
    required this.onPrev,
    required this.onNext,
    super.key,
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                friendlyDate(localDateString(date)),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
