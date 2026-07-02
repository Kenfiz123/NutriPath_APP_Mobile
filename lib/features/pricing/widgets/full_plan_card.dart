import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';

class FullPlanCard extends StatelessWidget {
  const FullPlanCard({required this.plan, required this.billing, super.key});

  final Plan plan;
  final String billing;

  @override
  Widget build(BuildContext context) {
    final color = switch (plan.id) {
      'svip' => AppColors.amber,
      'vip' => AppColors.emerald,
      _ => AppColors.blue,
    };
    final quote = plan.pricePreview;
    final price = quote?.total ?? plan.monthlyPrice;
    return GestureDetector(
      onTap: () => _showPlanDetailsSheet(context, color),
      child: NutriCard(
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
                          : AppColors.muted,
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
                    context.go('${AppRoutes.checkout}?plan=${plan.id}&billing=$billing'),
                style: FilledButton.styleFrom(backgroundColor: color),
                child: const Text('Chọn gói này'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPlanDetailsSheet(BuildContext context, Color color) {
    final quote = plan.pricePreview;
    final price = quote?.total ?? plan.monthlyPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ),
                      TierChip(tier: plan.id),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.id == 'free'
                        ? 'Miễn phí trọn đời'
                        : '${formatVnd(price)} / ${billing == 'annual' ? 'Năm' : 'Tháng'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Quyền lợi & Tính năng chi tiết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final feature in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            asBool(feature['included'])
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: asBool(feature['included'])
                                ? color
                                : AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              asString(feature['label']),
                              style: const TextStyle(fontSize: 15, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Quy tắc bảo hành & Cam kết',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPolicyItem(
                    Icons.replay_30,
                    'Chính sách hoàn tiền 100%',
                    'Hoàn trả 100% chi phí trong vòng 7 ngày đầu tiên sử dụng nếu bạn không hài lòng với dịch vụ hoặc có lỗi hệ thống phát sinh mà không được khắc phục.',
                  ),
                  _buildPolicyItem(
                    Icons.security,
                    'Bảo hành vận hành & Uptime',
                    'Cam kết hệ thống hoạt động ổn định với thời gian uptime 99.9%. Hỗ trợ kỹ thuật và giải quyết sự cố phát sinh của gói dịch vụ trong tối đa 24 giờ.',
                  ),
                  _buildPolicyItem(
                    Icons.lock_outline,
                    'Bảo mật thông tin dữ liệu',
                    'Thông tin sức khỏe, thực đơn cá nhân và dữ liệu thanh toán của bạn được mã hóa an toàn tuyệt đối, tuân thủ các quy định bảo mật.',
                  ),
                  _buildPolicyItem(
                    Icons.cancel_presentation_outlined,
                    'Hủy gia hạn linh hoạt',
                    'Bạn có thể dễ dàng hủy tính năng tự động gia hạn bất cứ lúc nào trong trang cá nhân mà không chịu thêm bất kỳ khoản phí phạt nào.',
                  ),
                  const SizedBox(height: 32),
                  if (plan.id != 'free')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('${AppRoutes.checkout}?plan=${plan.id}&billing=$billing');
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Đăng ký gói ngay',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
