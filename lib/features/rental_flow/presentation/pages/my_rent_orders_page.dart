import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rent_order.dart';
import '../widgets/rent_order_deadline_banner.dart';

class MyRentOrdersPage extends ConsumerStatefulWidget {
  const MyRentOrdersPage({super.key});

  @override
  ConsumerState<MyRentOrdersPage> createState() => _MyRentOrdersPageState();
}

class _MyRentOrdersPageState extends ConsumerState<MyRentOrdersPage> {
  String? _cancellingOrderId;
  String? _hidingOrderId;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(myRentOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _OrdersHeader(
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.goNamed(RouteNames.profile);
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(myRentOrdersProvider),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            108,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: orders.when(
                              loading: () => const SizedBox(
                                height: 320,
                                child: AppLoadingView(message: '正在加载租房订单'),
                              ),
                              error: (error, _) => SizedBox(
                                height: 320,
                                child: AppApiErrorView(
                                  message: '租房订单加载失败，请确认已登录后重试',
                                  onRetry: () =>
                                      ref.invalidate(myRentOrdersProvider),
                                ),
                              ),
                              data: (items) => _OrderList(
                                orders: items,
                                cancellingOrderId: _cancellingOrderId,
                                hidingOrderId: _hidingOrderId,
                                onCancel: _cancelOrder,
                                onHide: _hideOrder,
                                onPaymentExpired: () =>
                                    ref.invalidate(myRentOrdersProvider),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(RentOrder order) async {
    final needsRefund = order.status == RentOrderStatus.pendingLandlordSign;
    final discardsDraft =
        order.status == RentOrderStatus.created ||
        order.status == RentOrderStatus.pendingRealName ||
        order.status == RentOrderStatus.pendingContract;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          needsRefund
              ? '取消并退款'
              : discardsDraft
              ? '取消租住申请'
              : '取消订单',
        ),
        content: Text(
          needsRefund
              ? '订单已支付。确认取消「${order.houseName}」并将支付款原路退回吗？'
              : discardsDraft
              ? '确认退出「${order.houseName}」的办理流程吗？签署前草稿不会保留。'
              : '确认取消「${order.houseName}」的租房订单吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(needsRefund ? '确认退款' : '确认取消'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingOrderId = order.id);
    try {
      final updated = await ref
          .read(rentalFlowServiceProvider)
          .cancelRentOrder(order.id);
      ref.invalidate(myRentOrdersProvider);
      if (!mounted) return;
      AppToast.show(
        context,
        updated.status == RentOrderStatus.refundPending
            ? '退款申请已提交，支付款将原路退回'
            : discardsDraft
            ? '租住申请已取消，房源已恢复原始状态'
            : '订单已取消',
        type: AppToastType.success,
      );
    } on Object {
      if (!mounted) return;
      AppToast.show(context, '取消订单失败，请稍后重试', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _cancellingOrderId = null);
    }
  }

  Future<void> _hideOrder(RentOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确认删除「${order.houseName}」的订单记录吗？删除后将不再显示。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _hidingOrderId = order.id);
    try {
      await ref.read(rentalFlowServiceProvider).hideRentOrder(order.id);
      ref.invalidate(myRentOrdersProvider);
      if (!mounted) return;
      AppToast.show(context, '订单记录已删除', type: AppToastType.success);
    } on Object {
      if (!mounted) return;
      AppToast.show(context, '删除记录失败，请稍后重试', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _hidingOrderId = null);
    }
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.cancellingOrderId,
    required this.hidingOrderId,
    required this.onCancel,
    required this.onHide,
    required this.onPaymentExpired,
  });

  final List<RentOrder> orders;
  final String? cancellingOrderId;
  final String? hidingOrderId;
  final ValueChanged<RentOrder> onCancel;
  final ValueChanged<RentOrder> onHide;
  final VoidCallback onPaymentExpired;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox(
        height: 320,
        child: AppEmptyView(message: '暂无租房订单'),
      );
    }

    return Column(
      children: [
        for (final order in orders) ...[
          _RentOrderCard(
            order: order,
            isCancelling: cancellingOrderId == order.id,
            isHiding: hidingOrderId == order.id,
            onCancel: onCancel,
            onHide: onHide,
            onPaymentExpired: onPaymentExpired,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _RentOrderCard extends StatelessWidget {
  const _RentOrderCard({
    required this.order,
    required this.isCancelling,
    required this.isHiding,
    required this.onCancel,
    required this.onHide,
    required this.onPaymentExpired,
  });

  final RentOrder order;
  final bool isCancelling;
  final bool isHiding;
  final ValueChanged<RentOrder> onCancel;
  final ValueChanged<RentOrder> onHide;
  final VoidCallback onPaymentExpired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.houseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                ),
              ),
              _StatusChip(
                status: order.status,
                isPlatform: order.isPlatformSource,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(order.address, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '下单时间：${_formatOrderTime(order.createdAt)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${order.leaseMonths}个月 · ${order.paymentMethod} · 首笔￥${order.firstPaymentAmount}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_hasActiveDeadline(order)) ...[
            RentOrderDeadlineBanner(order: order, onExpired: onPaymentExpired),
            const SizedBox(height: AppSpacing.md),
          ],
          if (order.status == RentOrderStatus.refundPending ||
              order.status == RentOrderStatus.refunded ||
              order.status == RentOrderStatus.refundFailed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                switch (order.status) {
                  RentOrderStatus.refundPending => '房东未签署合同，退款正在原路退回',
                  RentOrderStatus.refunded => '退款已原路退回',
                  RentOrderStatus.refundFailed => '退款异常，请联系客服',
                  _ => '',
                },
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
          Row(
            children: [
              if (_canCancel(order.status) || _canHide(order.status)) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isOrderActionRunning
                        ? null
                        : () => _canHide(order.status)
                              ? onHide(order)
                              : onCancel(order),
                    child: Text(_orderActionLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pushNamed(
                    RouteNames.rentOrderDetail,
                    pathParameters: {'orderId': order.id},
                  ),
                  child: const Text('订单详情'),
                ),
              ),
              if (!_isContinueDisabled(order.status)) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _continueOrder(context, order),
                    child: Text(_continueOrderLabel(order)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _continueOrder(BuildContext context, RentOrder order) {
    final routeName = switch (order.status) {
      RentOrderStatus.created ||
      RentOrderStatus.pendingRealName => RouteNames.realNameAuth,
      RentOrderStatus.pendingContract => RouteNames.leaseContract,
      RentOrderStatus.pendingPayment => RouteNames.rentalPayment,
      RentOrderStatus.pendingSign => RouteNames.onlineSign,
      RentOrderStatus.pendingLandlordSign => RouteNames.waitingLandlordSign,
      RentOrderStatus.refundPending ||
      RentOrderStatus.refunded ||
      RentOrderStatus.refundFailed => RouteNames.rentOrders,
      RentOrderStatus.completed => RouteNames.lease,
      RentOrderStatus.cancelled => RouteNames.rentOrders,
    };
    if (routeName == RouteNames.lease || routeName == RouteNames.rentOrders) {
      context.pushNamed(routeName);
      return;
    }
    if (routeName == RouteNames.realNameAuth) {
      context.pushNamed(routeName, queryParameters: {'orderId': order.id});
      return;
    }
    context.pushNamed(routeName, pathParameters: {'orderId': order.id});
  }

  bool get _isOrderActionRunning => isCancelling || isHiding;

  String get _orderActionLabel {
    if (isHiding) return '删除中';
    if (isCancelling) return '取消中';
    if (_canHide(order.status)) return '删除记录';
    if (order.status == RentOrderStatus.pendingLandlordSign) {
      return '取消并退款';
    }
    return '取消订单';
  }
}

bool _canCancel(RentOrderStatus status) {
  return status != RentOrderStatus.completed &&
      status != RentOrderStatus.cancelled &&
      status != RentOrderStatus.refundPending &&
      status != RentOrderStatus.refunded &&
      status != RentOrderStatus.refundFailed;
}

bool _canHide(RentOrderStatus status) =>
    status == RentOrderStatus.cancelled || status == RentOrderStatus.refunded;

bool _isContinueDisabled(RentOrderStatus status) =>
    status == RentOrderStatus.cancelled ||
    status == RentOrderStatus.refundPending ||
    status == RentOrderStatus.refunded ||
    status == RentOrderStatus.refundFailed;

bool _hasActiveDeadline(RentOrder order) {
  if (order.status == RentOrderStatus.pendingPayment) {
    return order.paymentDeadline != null;
  }
  return switch (order.status) {
    RentOrderStatus.created ||
    RentOrderStatus.pendingRealName ||
    RentOrderStatus.pendingContract ||
    RentOrderStatus.pendingSign => order.prePaymentDeadline != null,
    _ => false,
  };
}

String _formatOrderTime(DateTime? value) {
  if (value == null) return '--';
  final local = value.toLocal();
  return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isPlatform});

  final RentOrderStatus status;
  final bool isPlatform;

  @override
  Widget build(BuildContext context) {
    final isActive =
        status != RentOrderStatus.completed &&
        status != RentOrderStatus.cancelled &&
        status != RentOrderStatus.refunded;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryLight : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        _rentOrderStatusLabel(status, isPlatform: isPlatform),
        style: AppTextStyles.bodySmall.copyWith(
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppIcon.iconBack,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text('我的订单', style: AppTextStyles.normalPageTitle),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

String _rentOrderStatusLabel(
  RentOrderStatus status, {
  required bool isPlatform,
}) {
  return switch (status) {
    RentOrderStatus.created || RentOrderStatus.pendingRealName => '待实名',
    RentOrderStatus.pendingContract => '待确认合同',
    RentOrderStatus.pendingPayment => '待支付',
    RentOrderStatus.pendingSign => '待签约',
    RentOrderStatus.pendingLandlordSign => isPlatform ? '平台盖章中' : '待房东签约',
    RentOrderStatus.refundPending => '退款处理中',
    RentOrderStatus.refunded => '退款成功',
    RentOrderStatus.refundFailed => '退款异常，请联系客服',
    RentOrderStatus.completed => '租约已生成',
    RentOrderStatus.cancelled => '已取消',
  };
}

String _continueOrderLabel(RentOrder order) {
  return switch (order.status) {
    RentOrderStatus.created || RentOrderStatus.pendingRealName => '去实名',
    RentOrderStatus.pendingContract => '确认合同',
    RentOrderStatus.pendingPayment => '去支付',
    RentOrderStatus.pendingSign => '去签署',
    RentOrderStatus.pendingLandlordSign =>
      order.isPlatformSource ? '查看合同状态' : '查看签约进度',
    RentOrderStatus.refundPending => '退款处理中',
    RentOrderStatus.refunded => '退款已完成',
    RentOrderStatus.refundFailed => '请联系客服',
    RentOrderStatus.completed => '查看租约',
    RentOrderStatus.cancelled => '订单已取消',
  };
}
