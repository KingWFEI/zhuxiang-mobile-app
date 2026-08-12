import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/rent_order.dart';

class RentOrderDeadlineBanner extends StatefulWidget {
  const RentOrderDeadlineBanner({
    required this.order,
    this.onExpired,
    super.key,
  });

  final RentOrder order;
  final VoidCallback? onExpired;

  @override
  State<RentOrderDeadlineBanner> createState() =>
      _RentOrderDeadlineBannerState();
}

class _RentOrderDeadlineBannerState extends State<RentOrderDeadlineBanner> {
  Timer? _timer;
  late Duration _remaining;
  bool _expiredNotified = false;

  DateTime? get _deadline =>
      widget.order.status == RentOrderStatus.pendingPayment
      ? widget.order.paymentDeadline
      : widget.order.prePaymentDeadline;

  @override
  void initState() {
    super.initState();
    _remaining = _calculateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RentOrderDeadlineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_deadline != _deadlineFor(oldWidget.order)) {
      _expiredNotified = false;
      _remaining = _calculateRemaining();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_deadline == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _calculateRemaining();
      setState(() => _remaining = next);
      if (next == Duration.zero && !_expiredNotified) {
        _expiredNotified = true;
        _timer?.cancel();
        // 给后端超时任务留出一次扫描时间，再刷新页面状态。
        Future<void>.delayed(const Duration(seconds: 12), () {
          if (mounted) widget.onExpired?.call();
        });
      }
    });
  }

  Duration _calculateRemaining() {
    final deadline = _deadline;
    if (deadline == null) return Duration.zero;
    final value = deadline.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  @override
  Widget build(BuildContext context) {
    if (_deadline == null) return const SizedBox.shrink();
    final seconds = _remaining.inSeconds;
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    final expired = _remaining == Duration.zero;
    final action = switch (widget.order.status) {
      RentOrderStatus.created || RentOrderStatus.pendingRealName => '完成实名',
      RentOrderStatus.pendingContract => '确认合同',
      RentOrderStatus.pendingSign => '完成签署',
      RentOrderStatus.pendingPayment => '完成支付',
      RentOrderStatus.pendingLandlordSign =>
        widget.order.isPlatformSource ? '等待平台确认合同' : '等待房东签署',
      RentOrderStatus.refundPending => '等待退款完成',
      RentOrderStatus.refunded => '退款已完成',
      RentOrderStatus.refundFailed => '联系平台处理退款',
      RentOrderStatus.completed => '查看租约',
      RentOrderStatus.cancelled => '重新申请',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 19, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              expired
                  ? '办理时间已到，订单即将关闭并释放房源'
                  : '请在 ${_twoDigits(minutes)}:${_twoDigits(remainder)} 内$action',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime? _deadlineFor(RentOrder order) =>
    order.status == RentOrderStatus.pendingPayment
    ? order.paymentDeadline
    : order.prePaymentDeadline;

String _twoDigits(int value) => value.toString().padLeft(2, '0');
