import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/rental_flow_providers.dart';

class WaitingLandlordSignPage extends ConsumerStatefulWidget {
  const WaitingLandlordSignPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<WaitingLandlordSignPage> createState() =>
      _WaitingLandlordSignPageState();
}

class _WaitingLandlordSignPageState
    extends ConsumerState<WaitingLandlordSignPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final controller = ref.read(rentalFlowControllerProvider.notifier);
    await controller.loadContractPreview(widget.orderId);
    if (!mounted ||
        ref.read(rentalFlowControllerProvider).errorMessage != null) {
      return;
    }
    await controller.refreshContractSigning(widget.orderId);
    if (mounted) ref.invalidate(myRentOrdersProvider);
  }

  Future<void> _refresh() async {
    await ref
        .read(rentalFlowControllerProvider.notifier)
        .refreshContractSigning(widget.orderId);
    if (mounted) ref.invalidate(myRentOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    final order = state.order;
    final signing = state.signingStatus;
    final completed = signing?.isCompleted == true;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        title: const Text('等待房东签约'),
        centerTitle: true,
        backgroundColor: AppColors.authBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
          ? _ErrorState(message: state.errorMessage!, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                120,
              ),
              children: [
                _ResultHeader(completed: completed),
                const SizedBox(height: AppSpacing.xl),
                _ProgressCard(completed: completed),
                const SizedBox(height: AppSpacing.lg),
                _OrderCard(
                  houseName: order?.houseName ?? '租住房源',
                  orderNo: order?.orderNo ?? '--',
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    context.pushReplacementNamed(RouteNames.rentOrders),
                child: const Text('返回订单'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: state.isSubmitting ? null : _refresh,
                child: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(completed ? '查看最新状态' : '刷新签约状态'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: Icon(
            completed ? Icons.done_all_rounded : Icons.hourglass_top_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          completed ? '房东已完成签约' : '支付成功，等待房东签约',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          completed ? '双方签署已完成，租赁合同正式生效。' : '合同已经发送给房东。房东签署完成后，租赁合同将正式生效。',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          const _ProgressItem(label: '租客完成合同签署', done: true),
          const _ProgressLine(done: true),
          const _ProgressItem(label: '首笔费用支付成功', done: true),
          _ProgressLine(done: completed),
          _ProgressItem(label: '房东完成合同签署', done: completed, active: !completed),
          _ProgressLine(done: completed),
          _ProgressItem(label: '租赁合同正式生效', done: completed),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.label,
    required this.done,
    this.active = false,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.success : AppColors.textMuted;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.schedule,
          color: color,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
        Text(
          done
              ? '已完成'
              : active
              ? '进行中'
              : '待完成',
          style: AppTextStyles.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 2,
        height: 28,
        margin: const EdgeInsets.only(left: 11),
        color: done ? AppColors.success : AppColors.border,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.houseName, required this.orderNo});

  final String houseName;
  final String orderNo;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('订单信息', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: '租住房源', value: houseName),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: '订单编号', value: orderNo),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}
