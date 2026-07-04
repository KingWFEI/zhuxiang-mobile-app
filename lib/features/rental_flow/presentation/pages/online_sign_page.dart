import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../home/data/providers/home_providers.dart';
import '../../../house/application/house_search_notifier.dart';
import '../../../house/data/providers/house_providers.dart';
import '../../../lease/data/providers/lease_providers.dart';
import '../../../lease/domain/entities/lease.dart';
import '../../../profile/data/providers/profile_providers.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/agreement_checkbox.dart';
import '../widgets/rental_flow_bottom_bar.dart';
import '../widgets/rental_flow_page_shell.dart';

class OnlineSignPage extends ConsumerStatefulWidget {
  const OnlineSignPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OnlineSignPage> createState() => _OnlineSignPageState();
}

class _OnlineSignPageState extends ConsumerState<OnlineSignPage> {
  bool _agreed = false;
  bool _signed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    final order = state.order;
    final contract = state.contractPreview;
    return RentalFlowPageShell(
      title: '在线签约',
      step: RentalFlowStep.onlineSign,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: _load,
      bottomNavigationBar: RentalFlowBottomBar(
        primaryLabel: '完成签约',
        isLoading: state.isSubmitting,
        onPrimary: _submit,
      ),
      children: [
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '签约信息',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoRow(label: '签约人', value: contract?.tenantName ?? '租客'),
              InfoRow(
                label: '合同房源',
                value: contract?.houseName ?? order?.houseName ?? '租住房源',
              ),
              InfoRow(label: '合同编号', value: _contractNo(contract?.contractNo)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '电子签名',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _signed = true),
                child: Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _signed
                        ? const Color(0xFFEAF8EF)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _signed
                          ? AppColors.success
                          : AppColors.primarySoft,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _signed
                            ? Icons.check_circle_outline
                            : Icons.draw_outlined,
                        color: _signed ? AppColors.success : AppColors.primary,
                        size: 36,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _signed ? '已完成签名确认' : '点击此处确认签名',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _signed
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '本期为签名占位，后续可接电子签章服务',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AgreementCheckbox(
          value: _agreed,
          text: '我确认本人已阅读并同意签署该租赁合同',
          onChanged: (value) => setState(() => _agreed = value),
        ),
      ],
    );
  }

  void _load() {
    ref
        .read(rentalFlowControllerProvider.notifier)
        .loadContractPreview(widget.orderId);
  }

  Future<void> _submit() async {
    if (!_signed) {
      AppToast.show(context, '请先完成电子签名确认', type: AppToastType.error);
      return;
    }
    if (!_agreed) {
      AppToast.show(context, '请先确认签约协议', type: AppToastType.error);
      return;
    }
    final ok = await ref
        .read(rentalFlowControllerProvider.notifier)
        .submitOnlineSign(widget.orderId);
    if (!mounted || !ok) return;
    final houseId = ref.read(rentalFlowControllerProvider).order?.houseId;
    if (houseId != null && houseId.isNotEmpty) {
      ref
          .read(locallyRentedHouseIdsProvider.notifier)
          .update((ids) => {...ids, houseId});
    }
    ref.invalidate(homeDataProvider);
    ref.invalidate(houseSearchProvider);
    ref.invalidate(leaseControllerProvider);
    ref.invalidate(currentHomeProvider);
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

String _contractNo(String? value) {
  if (value == null || value.isEmpty) return '--';
  return value;
}
