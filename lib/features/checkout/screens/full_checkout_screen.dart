import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/models.dart';
import '../../../core/widgets.dart';
import '../widgets/quote_card.dart';

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
  final String _paymentMethod = 'stripe';
  String? _stripeSessionId;
  int _trialDays = 0;
  bool _busy = false;
  late String _billing;
  late Future<CheckoutQuote> _quoteFuture;

  bool get _supportsNativeStripeSheet {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

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

  void _reloadQuote() {
    setState(() {
      _quoteFuture = _quote();
    });
  }

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
                  const SizedBox(height: 12),
                  const Text(
                    'Phương thức thanh toán:',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const Text(
                    'Stripe (Thanh toán bảo mật trong app)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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
              QuoteCard(quote: snapshot.data!),
            if (_stripeSessionId != null)
              NutriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Stripe Checkout'),
                    Text(
                      'Session: $_stripeSessionId',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _busy
                          ? null
                          : () => _syncStripeCheckout(context),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Xac minh thanh toan Stripe'),
                    ),
                  ],
                ),
              ),
            FilledButton.icon(
              onPressed: snapshot.hasData && !_busy
                  ? () => _pay(context)
                  : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                _paymentMethod == 'stripe'
                    ? (_supportsNativeStripeSheet
                          ? 'Thanh toan trong app'
                          : 'Thanh toan qua Stripe')
                    : 'Xác nhận thanh toán demo',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pay(BuildContext context) async {
    if (_paymentMethod == 'stripe') {
      await _startStripeCheckout(context);
      return;
    }
    await _payDemo(context);
  }

  Future<void> _startStripeCheckout(BuildContext context) async {
    if (_supportsNativeStripeSheet) {
      await _startStripePaymentSheet(context);
      return;
    }

    setState(() => _busy = true);
    try {
      final json = await ref
          .read(apiClientProvider)
          .createStripeCheckoutSession({
            'planId': widget.initialPlanId,
            'billing': _billing,
            'discountCode': _discount.text.trim(),
            'trialDays': _trialDays,
          });
      final memberJson = json['member'];
      if (memberJson != null) {
        final updated = Member.fromJson(memberJson);
        await ref.read(sessionControllerProvider).syncMember(updated);
        if (context.mounted) {
          showSnack(context, 'Goi da duoc kich hoat.');
          context.go(AppRoutes.profile);
        }
        return;
      }

      final checkoutUrl = asString(json['checkoutUrl']);
      final sessionId = asString(json['sessionId']);
      if (checkoutUrl.isEmpty || sessionId.isEmpty) {
        throw const ApiException('Stripe Checkout chua san sang.');
      }
      setState(() => _stripeSessionId = sessionId);
      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback) {
          throw const ApiException('Khong mo duoc Stripe Checkout.');
        }
      }
      if (context.mounted) {
        showSnack(context, 'Da mo Stripe Checkout. Quay lai app de xac minh.');
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startStripePaymentSheet(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final json = await ref.read(apiClientProvider).createStripePaymentIntent({
        'planId': widget.initialPlanId,
        'billing': _billing,
        'discountCode': _discount.text.trim(),
        'trialDays': _trialDays,
      });
      final memberJson = json['member'];
      if (memberJson != null) {
        final updated = Member.fromJson(memberJson);
        await ref.read(sessionControllerProvider).syncMember(updated);
        if (context.mounted) {
          showSnack(context, 'Goi da duoc kich hoat.');
          context.go(AppRoutes.profile);
        }
        return;
      }

      final publishableKey = asString(json['publishableKey']);
      final clientSecret = asString(json['clientSecret']);
      final paymentIntentId = asString(json['paymentIntentId']);
      if (publishableKey.isEmpty ||
          clientSecret.isEmpty ||
          paymentIntentId.isEmpty) {
        throw const ApiException('Stripe PaymentSheet chua san sang.');
      }

      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: asString(
            json['merchantDisplayName'],
            'NutriPath',
          ),
          style: ThemeMode.system,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      final synced = await ref
          .read(apiClientProvider)
          .syncStripePaymentIntent(paymentIntentId);
      final syncedMemberJson = synced['member'];
      if (syncedMemberJson != null && asString(synced['status']) == 'paid') {
        final updated = Member.fromJson(syncedMemberJson);
        await ref.read(sessionControllerProvider).syncMember(updated);
        if (context.mounted) {
          showSnack(context, 'Stripe da xac nhan thanh toan.');
          context.go(AppRoutes.profile);
        }
      } else if (context.mounted) {
        showSnack(
          context,
          'Stripe dang xu ly: ${asString(synced['paymentStatus'], asString(synced['status'], 'pending'))}.',
        );
      }
    } on StripeException catch (error) {
      final stripeError = error.error;
      final message = stripeError.localizedMessage ?? stripeError.message ?? '';
      if (context.mounted) {
        showSnack(
          context,
          stripeError.code == FailureCode.Canceled
              ? 'Ban da huy thanh toan Stripe.'
              : (message.isEmpty
                    ? 'Thanh toan Stripe khong thanh cong.'
                    : message),
        );
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncStripeCheckout(BuildContext context) async {
    final sessionId = _stripeSessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    setState(() => _busy = true);
    try {
      final json = await ref
          .read(apiClientProvider)
          .syncStripeCheckoutSession(sessionId);
      final memberJson = json['member'];
      if (memberJson != null && asString(json['status']) == 'paid') {
        final updated = Member.fromJson(memberJson);
        await ref.read(sessionControllerProvider).syncMember(updated);
        if (context.mounted) {
          showSnack(context, 'Stripe da xac nhan thanh toan.');
          context.go(AppRoutes.profile);
        }
      } else if (context.mounted) {
        showSnack(
          context,
          'Stripe chua xac nhan thanh toan: ${asString(json['paymentStatus'], asString(json['status'], 'pending'))}.',
        );
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payDemo(BuildContext context) async {
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
        context.go(AppRoutes.profile);
      }
    } catch (e) {
      if (context.mounted) showSnack(context, readableError(e));
    }
  }
}
