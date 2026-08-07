import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/rent_fee_detail_card.dart';
import '../widgets/rent_order_deadline_banner.dart';
import '../widgets/rental_flow_bottom_bar.dart';
import '../widgets/rental_flow_page_shell.dart';
import 'alipay_webview_page.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    final payment = state.paymentInfo;
    final order = state.order;
    final selected = payment?.selectedPaymentMethod;
    return RentalFlowPageShell(
      title: '支付',
      step: RentalFlowStep.payment,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: _load,
      bottomNavigationBar: RentalFlowBottomBar(
        primaryLabel: '确认支付',
        isLoading: state.isSubmitting,
        onPrimary: _submit,
      ),
      children: [
        if (order?.paymentDeadline != null) ...[
          RentOrderDeadlineBanner(
            order: order!,
            onExpired: _handleDeadlineExpired,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        FlowCard(
          child: Column(
            children: [
              Text('首笔应付', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '￥${payment?.amount ?? 0}',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (payment != null)
          RentFeeDetailCard(
            monthlyRent: payment.monthlyRent,
            deposit: payment.deposit,
            serviceFee: payment.serviceFee,
          ),
        const SizedBox(height: AppSpacing.lg),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '支付方式',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final method in payment?.paymentMethods ?? const <String>[])
                _PaymentMethodTile(
                  method: method,
                  selected: selected == method,
                  onTap: () => ref
                      .read(rentalFlowControllerProvider.notifier)
                      .selectPaymentMethod(method),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _load() {
    ref
        .read(rentalFlowControllerProvider.notifier)
        .loadPaymentInfo(widget.orderId);
  }

  void _handleDeadlineExpired() {
    ref.invalidate(myRentOrdersProvider);
    if (!mounted) return;
    AppToast.show(context, '支付已超时，房源已释放');
    context.goNamed(RouteNames.rentOrders);
  }

  Future<void> _submit() async {
    final selected = ref
        .read(rentalFlowControllerProvider)
        .paymentInfo
        ?.selectedPaymentMethod;
    if (selected == null || selected.isEmpty) {
      AppToast.show(context, '请选择支付方式', type: AppToastType.error);
      return;
    }

    final channel = _channelForMethod(selected);
    final result = await ref
        .read(rentalFlowControllerProvider.notifier)
        .submitPayment(widget.orderId, selected, channel);
    if (!mounted || result == null) return;

    // 支付宝 H5 支付 → 打开 WebView
    if (result.needWebView) {
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AlipayWebViewPage(
            paymentUrl: result.paymentUrl!,
            orderId: widget.orderId,
            paymentNo: result.paymentNo,
          ),
        ),
      );
      if (!mounted) return;
      if (paid == true) {
        context.pushReplacementNamed(
          RouteNames.waitingLandlordSign,
          pathParameters: {'orderId': widget.orderId},
        );
      }
      return;
    }

    // mock 支付 → 进入等待房东签约页
    ref.invalidate(myRentOrdersProvider);
    context.pushReplacementNamed(
      RouteNames.waitingLandlordSign,
      pathParameters: {'orderId': widget.orderId},
    );
  }

  /// 支付方式显示名 → 后端渠道名
  String _channelForMethod(String method) {
    if (method.contains('支付宝') || method == 'alipay') return 'alipay';
    if (method.contains('微信') || method == 'wechat') return 'wechat';
    return 'mock';
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final String method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(method, style: AppTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}
