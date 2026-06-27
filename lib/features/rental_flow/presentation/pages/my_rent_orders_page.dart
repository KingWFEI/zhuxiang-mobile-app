import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rent_order.dart';

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
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(myRentOrdersProvider),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _OrdersHeader(
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.goNamed(RouteNames.profile);
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
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
                          child: AppErrorView(
                            message: '租房订单加载失败，请确认已登录后重试',
                            onRetry: () => ref.invalidate(myRentOrdersProvider),
                          ),
                        ),
                        data: (items) => _OrderList(
                          orders: items,
                          cancellingOrderId: _cancellingOrderId,
                          hidingOrderId: _hidingOrderId,
                          onCancel: _cancelOrder,
                          onHide: _hideOrder,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(RentOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消订单'),
        content: Text('确认取消「${order.houseName}」的租房订单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingOrderId = order.id);
    try {
      await ref.read(rentalFlowServiceProvider).cancelRentOrder(order.id);
      ref.invalidate(myRentOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('订单已取消')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('取消订单失败，请稍后重试')));
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('订单记录已删除')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('删除记录失败，请稍后重试')));
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
  });

  final List<RentOrder> orders;
  final String? cancellingOrderId;
  final String? hidingOrderId;
  final ValueChanged<RentOrder> onCancel;
  final ValueChanged<RentOrder> onHide;

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
  });

  final RentOrder order;
  final bool isCancelling;
  final bool isHiding;
  final ValueChanged<RentOrder> onCancel;
  final ValueChanged<RentOrder> onHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
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
              _StatusChip(status: order.status),
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
                    RouteNames.houseDetail,
                    pathParameters: {'houseId': order.houseId},
                  ),
                  child: const Text('查看房源'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: order.status == RentOrderStatus.cancelled
                      ? null
                      : () => _continueOrder(context, order),
                  child: Text(
                    order.status == RentOrderStatus.completed ? '查看租约' : '继续办理',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _continueOrder(BuildContext context, RentOrder order) {
    final routeName = switch (order.status) {
      RentOrderStatus.created ||
      RentOrderStatus.pendingRealName => RouteNames.realNameVerify,
      RentOrderStatus.pendingContract => RouteNames.leaseContract,
      RentOrderStatus.pendingPayment => RouteNames.rentalPayment,
      RentOrderStatus.pendingSign => RouteNames.onlineSign,
      RentOrderStatus.completed => RouteNames.lease,
      RentOrderStatus.cancelled => RouteNames.rentOrders,
    };
    if (routeName == RouteNames.lease || routeName == RouteNames.rentOrders) {
      context.pushNamed(routeName);
      return;
    }
    context.pushNamed(routeName, pathParameters: {'orderId': order.id});
  }

  bool get _isOrderActionRunning => isCancelling || isHiding;

  String get _orderActionLabel {
    if (isHiding) return '删除中';
    if (isCancelling) return '取消中';
    if (_canHide(order.status)) return '删除记录';
    return '取消订单';
  }
}

bool _canCancel(RentOrderStatus status) {
  return status != RentOrderStatus.completed &&
      status != RentOrderStatus.cancelled;
}

bool _canHide(RentOrderStatus status) => status == RentOrderStatus.cancelled;

String _formatOrderTime(DateTime? value) {
  if (value == null) return '--';
  final local = value.toLocal();
  return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RentOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive =
        status != RentOrderStatus.completed &&
        status != RentOrderStatus.cancelled;
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
        _rentOrderStatusLabel(status),
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
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.card),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -AppSpacing.sm,
            left: -AppSpacing.md,
            child: IconButton(onPressed: onBack, icon: AppIcon.iconBack),
          ),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '我的订单',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('查看租房流程进度，继续未完成的订单', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _rentOrderStatusLabel(RentOrderStatus status) {
  return switch (status) {
    RentOrderStatus.created || RentOrderStatus.pendingRealName => '待实名',
    RentOrderStatus.pendingContract => '待确认合同',
    RentOrderStatus.pendingPayment => '待支付',
    RentOrderStatus.pendingSign => '待签约',
    RentOrderStatus.completed => '已完成',
    RentOrderStatus.cancelled => '已取消',
  };
}
