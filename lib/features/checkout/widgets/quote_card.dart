import 'package:flutter/material.dart';

import '../../../core/models.dart';
import '../../../core/widgets.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({required this.quote, super.key});

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
