import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/lease.dart';
import '../widgets/current_lease_card.dart';
import '../widgets/lease_status_badge.dart';

class LeaseDetailPage extends ConsumerWidget {
  const LeaseDetailPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(leaseDetailProvider(leaseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('租约详情')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: detail.when(
            loading: () => const AppLoadingView(message: '正在加载租约详情'),
            error: (error, stackTrace) => AppErrorView(
              message: '租约详情加载失败',
              onRetry: () => ref.invalidate(leaseDetailProvider(leaseId)),
            ),
            data: (lease) => _LeaseDetailContent(
              lease: lease,
              onAction: (isCheckout) =>
                  _requestAction(context, ref, lease, isCheckout: isCheckout),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestAction(
    BuildContext context,
    WidgetRef ref,
    Lease lease, {
    required bool isCheckout,
  }) async {
    final user = ref.read(authControllerProvider).user;
    if (user?.isVerified != true) {
      // TODO: 实名认证完成后返回本详情页并恢复操作。
      context.pushNamed(RouteNames.realNameAuth);
      return;
    }
    final action = isCheckout ? '退租' : '续租';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认$action申请'),
        content: Text('确认对「${lease.houseName}」发起$action申请吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final controller = ref.read(leaseControllerProvider.notifier);
    final success = isCheckout
        ? await controller.checkout(lease.id)
        : await controller.renew(lease.id);
    if (!context.mounted) return;
    final state = ref.read(leaseControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? state.actionMessage ?? '$action申请已提交'
              : state.errorMessage ?? '$action申请失败',
        ),
      ),
    );
    if (success) ref.invalidate(leaseDetailProvider(leaseId));
  }
}

class _LeaseDetailContent extends StatelessWidget {
  const _LeaseDetailContent({required this.lease, required this.onAction});

  final Lease lease;
  final ValueChanged<bool> onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        108,
      ),
      children: [
        _DetailCard(
          title: '房源信息',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lease.houseName,
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  LeaseStatusBadge(label: lease.status.label),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(lease.houseSummary, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(lease.houseAddress, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailCard(
          title: '租客信息',
          child: Column(
            children: [
              _DetailRow(label: '租客姓名', value: lease.tenantName),
              _DetailRow(label: '手机号', value: lease.maskedTenantPhone),
              _DetailRow(label: '身份证号', value: lease.maskedIdCard),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailCard(
          title: '租约信息',
          child: Column(
            children: [
              _DetailRow(
                label: '租期',
                value:
                    '${formatLeaseDate(lease.startDate)} - ${formatLeaseDate(lease.endDate)}',
              ),
              _DetailRow(
                label: '月租金',
                value: '￥${formatLeaseMoney(lease.monthlyRent)}',
              ),
              _DetailRow(
                label: '押金',
                value: '￥${formatLeaseMoney(lease.deposit)}',
              ),
              _DetailRow(label: '付款方式', value: lease.paymentMethod),
              _DetailRow(label: '合同状态', value: lease.contractStatus.label),
              _DetailRow(label: '账单状态', value: lease.billStatus.label),
              _DetailRow(
                label: '门锁权限',
                value: lease.lockPermissionStatus.label,
                valueColor:
                    lease.lockPermissionStatus ==
                        LeaseLockPermissionStatus.active
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ),
        if (lease.canOperate) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailCard(
            title: '租后服务',
            child: Column(
              children: [
                _ServiceButton(
                  icon: Icons.receipt_long_outlined,
                  label: '查看账单',
                  onTap: () => context.pushNamed(RouteNames.bill),
                ),
                _ServiceButton(
                  icon: Icons.description_outlined,
                  label: '查看合同',
                  onTap: () => _showTodo(context, '合同查看功能开发中'),
                ),
                _ServiceButton(
                  icon: Icons.lock_clock_outlined,
                  label: '查看开锁记录',
                  onTap: () => context.pushNamed(RouteNames.lock),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onAction(false),
                        child: const Text('续租'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onAction(true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('退租'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showTodo(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
