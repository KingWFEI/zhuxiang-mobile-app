import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rent_order.dart';

class RentOrderDetailPage extends ConsumerStatefulWidget {
  const RentOrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<RentOrderDetailPage> createState() =>
      _RentOrderDetailPageState();
}

class _RentOrderDetailPageState extends ConsumerState<RentOrderDetailPage> {
  RentOrder? _order;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(rentalFlowServiceProvider)
          .loadRentOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('订单详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || order == null
          ? AppErrorView(message: '订单详情加载失败', onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                children: [
                  if (_statusMessage(order.status) case final message?) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: order.status == RentOrderStatus.refundFailed
                              ? AppColors.error
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _section('订单信息', [
                    _row('订单编号', order.orderNo),
                    _row('订单状态', _statusLabel(order.status)),
                    _row(
                      '房源',
                      [
                        order.houseName,
                        order.roomName,
                      ].where((v) => v.isNotEmpty).join(' '),
                    ),
                    _row('地址', order.address),
                  ]),
                  _section('租住信息', [
                    _row('起租日期', _date(order.startDate)),
                    _row('租期', '${order.leaseMonths}个月'),
                    _row('付款方式', order.paymentMethod),
                    _row('入住人数', '${order.tenantCount}人'),
                    _row(
                      '首笔金额',
                      '￥${order.firstPaymentAmount.toStringAsFixed(2)}',
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const Divider(height: 24),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: AppTextStyles.bodySmall)),
        Expanded(
          child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.right),
        ),
      ],
    ),
  );
}

String? _statusMessage(RentOrderStatus status) => switch (status) {
  RentOrderStatus.refundPending => '房东未签署合同，退款正在原路退回',
  RentOrderStatus.refunded => '退款已原路退回',
  RentOrderStatus.refundFailed => '退款异常，请联系客服',
  _ => null,
};

String _statusLabel(RentOrderStatus status) => switch (status) {
  RentOrderStatus.created => '已创建',
  RentOrderStatus.pendingRealName => '待实名',
  RentOrderStatus.pendingContract => '待确认合同',
  RentOrderStatus.pendingPayment => '待支付',
  RentOrderStatus.pendingSign => '待签约',
  RentOrderStatus.pendingLandlordSign => '待房东签约',
  RentOrderStatus.refundPending => '退款处理中',
  RentOrderStatus.refunded => '退款成功',
  RentOrderStatus.refundFailed => '退款异常，请联系客服',
  RentOrderStatus.completed => '租约已生成',
  RentOrderStatus.cancelled => '订单已取消',
};

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
