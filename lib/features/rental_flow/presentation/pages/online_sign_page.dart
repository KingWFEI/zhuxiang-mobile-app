import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_webview_page.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/contract_signing.dart';
import '../../domain/entities/rent_order.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/rental_flow_bottom_bar.dart';
import '../widgets/rental_flow_page_shell.dart';
import '../widgets/rent_order_deadline_banner.dart';

class OnlineSignPage extends ConsumerStatefulWidget {
  const OnlineSignPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OnlineSignPage> createState() => _OnlineSignPageState();
}

class _OnlineSignPageState extends ConsumerState<OnlineSignPage> {
  bool _handlingCompletion = false;

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
    final signing = state.signingStatus;
    final platformHouse = order?.isPlatformSource == true;
    return RentalFlowPageShell(
      title: '在线签约',
      step: RentalFlowStep.onlineSign,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: _load,
      bottomNavigationBar: RentalFlowBottomBar(
        primaryLabel: signing?.currentUserSigned == true ? '刷新签署状态' : '去签署',
        isLoading: state.isSubmitting,
        onPrimary: signing?.currentUserSigned == true
            ? () => _refreshStatus(showPendingMessage: true)
            : _openSigningPage,
      ),
      children: [
        if (order?.prePaymentDeadline != null) ...[
          RentOrderDeadlineBanner(
            order: order!,
            onExpired: _handleDeadlineExpired,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
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
                '电子合同签署',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              _SignStatusRow(
                label: '租户',
                signed: signing?.tenantSigned == true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SignStatusRow(
                label: platformHouse ? '平台企业印章' : '房东',
                signed: signing?.lessorSigned == true,
                signedLabel: platformHouse ? '已自动盖章' : '已签署',
                pendingLabel: platformHouse ? '自动盖章中' : '待签署',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _statusHint(signing, platformHouse: platformHouse),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _load() async {
    final controller = ref.read(rentalFlowControllerProvider.notifier);
    await controller.loadContractPreview(widget.orderId);
    if (!mounted ||
        ref.read(rentalFlowControllerProvider).errorMessage != null) {
      return;
    }
    if (ref.read(rentalFlowControllerProvider).order?.status ==
        RentOrderStatus.pendingLandlordSign) {
      context.pushReplacementNamed(
        RouteNames.waitingLandlordSign,
        pathParameters: {'orderId': widget.orderId},
      );
      return;
    }

    final status = await controller.refreshContractSigning(widget.orderId);
    if (!mounted || status == null) return;
    if (status.readyForPayment) {
      await _completeFlow();
    }
  }

  Future<void> _openSigningPage() async {
    final controller = ref.read(rentalFlowControllerProvider.notifier);
    final entry = await controller.getContractSignEntry(widget.orderId);
    if (!mounted || entry == null) return;
    if (entry.isCompleted) {
      await _refreshStatus(showPendingMessage: false);
      return;
    }
    if (entry.currentUserSigned) {
      await _refreshStatus(showPendingMessage: true);
      return;
    }

    final signUrl = entry.signUrl;
    if (signUrl == null || !AppWebViewPage.supportsUrl(signUrl)) {
      AppToast.show(context, '未获取到有效的签署页面', type: AppToastType.error);
      return;
    }

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AppWebViewPage(title: '合同签署', initialUrl: signUrl),
        ),
      );
    } on Object {
      if (mounted) {
        AppToast.show(context, '签署页面打开失败', type: AppToastType.error);
      }
      return;
    }
    if (mounted) await _refreshStatus(showPendingMessage: true);
  }

  void _handleDeadlineExpired() {
    ref.invalidate(myRentOrdersProvider);
    if (!mounted) return;
    AppToast.show(context, '订单办理超时，房源已释放');
    context.goNamed(RouteNames.rentOrders);
  }

  Future<void> _refreshStatus({required bool showPendingMessage}) async {
    final status = await ref
        .read(rentalFlowControllerProvider.notifier)
        .refreshContractSigning(widget.orderId);
    if (!mounted || status == null) return;
    if (status.readyForPayment) {
      await _completeFlow();
      return;
    }
    if (showPendingMessage) {
      final platformHouse =
          ref.read(rentalFlowControllerProvider).order?.isPlatformSource ==
          true;
      AppToast.show(context, _statusHint(status, platformHouse: platformHouse));
    }
  }

  Future<void> _completeFlow() async {
    if (_handlingCompletion) return;
    _handlingCompletion = true;
    if (!mounted) return;
    context.pushReplacementNamed(
      RouteNames.rentalPayment,
      pathParameters: {'orderId': widget.orderId},
    );
  }
}

class _SignStatusRow extends StatelessWidget {
  const _SignStatusRow({
    required this.label,
    required this.signed,
    this.signedLabel = '已签署',
    this.pendingLabel = '待签署',
  });

  final String label;
  final bool signed;
  final String signedLabel;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    final color = signed ? AppColors.success : AppColors.textSecondary;
    return Row(
      children: [
        Icon(
          signed ? Icons.check_circle_outline : Icons.schedule_outlined,
          color: color,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Text(
          signed ? signedLabel : pendingLabel,
          style: AppTextStyles.bodyMedium.copyWith(color: color),
        ),
      ],
    );
  }
}

String _statusHint(
  ContractSigningStatus? status, {
  required bool platformHouse,
}) {
  if (status == null) return '点击“去签署”后将在 App 内打开 e签宝官方签署页面。';
  if (status.isCompleted) {
    return platformHouse ? '租客签署和平台企业盖章均已完成。' : '合同已完成签署。';
  }
  if (status.currentUserSigned) {
    return platformHouse ? '你已完成签署，平台正在自动加盖企业印章。' : '你已完成签署，正在等待另一方签署。';
  }
  return '合同尚未完成，请继续前往 e签宝签署。';
}

String _contractNo(String? value) {
  if (value == null || value.isEmpty) return '--';
  return value;
}
