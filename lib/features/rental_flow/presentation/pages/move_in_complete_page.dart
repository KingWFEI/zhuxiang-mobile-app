import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../lease/data/providers/lease_providers.dart';
import '../../../lease/domain/entities/lease.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/rental_flow_page_shell.dart';

class MoveInCompletePage extends ConsumerStatefulWidget {
  const MoveInCompletePage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<MoveInCompletePage> createState() => _MoveInCompletePageState();
}

class _MoveInCompletePageState extends ConsumerState<MoveInCompletePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(rentalFlowControllerProvider.notifier)
          .loadRentOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    final order = state.order;
    return RentalFlowPageShell(
      title: '租住成功',
      step: RentalFlowStep.success,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: () => ref
          .read(rentalFlowControllerProvider.notifier)
          .loadRentOrder(widget.orderId),
      children: [
        FlowCard(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 46,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('租住成功', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '欢迎入住${order?.houseName ?? '住享房源'}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              InfoRow(label: '租约编号', value: order?.orderNo ?? widget.orderId),
              InfoRow(label: '房源名称', value: order?.houseName ?? '租住房源'),
              InfoRow(
                label: '起租日期',
                value: order == null ? '-' : formatDate(order.startDate),
              ),
              const InfoRow(label: '门锁权限', value: '待授权'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: () => _openCurrentLeaseDetail(order?.houseId),
          style: ElevatedButton.styleFrom(
            fixedSize: const Size.fromHeight(48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('查看租约详情'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => context.goNamed(RouteNames.unlockRecords),
          style: OutlinedButton.styleFrom(
            fixedSize: const Size.fromHeight(48),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('查看开门记录'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => context.goNamed(RouteNames.home),
          child: const Text('返回首页'),
        ),
      ],
    );
  }

  Future<void> _openCurrentLeaseDetail(String? houseId) async {
    final leaseId = await _findCurrentLeaseId(houseId: houseId);
    if (!mounted) return;
    // 先回到首页（清空租房流程栈），再 push 租约详情，确保侧滑返回时回到首页而非退出 app
    final router = GoRouter.of(context);
    if (leaseId == null) {
      router.goNamed(RouteNames.home);
      router.pushNamed(RouteNames.lease);
      return;
    }
    router.goNamed(RouteNames.home);
    router.pushNamed(
      RouteNames.leaseDetail,
      pathParameters: {'leaseId': leaseId},
    );
  }

  Future<String?> _findCurrentLeaseId({String? houseId}) async {
    try {
      final leases = await ref.read(leaseServiceProvider).getMyLeases();
      Lease? fallback;
      for (final lease in leases) {
        if (!lease.isCurrent) continue;
        fallback ??= lease;
        if (houseId != null &&
            houseId.isNotEmpty &&
            lease.houseId == houseId &&
            lease.status == LeaseStatus.active) {
          return lease.id;
        }
      }
      if (houseId != null && houseId.isNotEmpty) {
        for (final lease in leases) {
          if (lease.isCurrent && lease.houseId == houseId) return lease.id;
        }
      }
      return fallback?.id;
    } on Object {
      return null;
    }
  }
}
