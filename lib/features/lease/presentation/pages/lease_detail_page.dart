import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../lock/data/models/tenant_lock_unlock_data.dart';
import '../../../lock/data/providers/tenant_lock_providers.dart';
import '../../data/providers/inspection_providers.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/lease_termination.dart';
import '../widgets/current_lease_card.dart';
import '../widgets/lease_action_grid.dart';
import '../widgets/lease_status_badge.dart';
import '../widgets/rent_bill_card.dart';

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
            error: (error, stackTrace) => AppApiErrorView(
              error: error,
              message: '租约详情加载失败',
              onRetry: () => ref.invalidate(leaseDetailProvider(leaseId)),
            ),
            data: (lease) => _LeaseDetailContent(
              lease: lease,
              onRenew: () => _requestRenew(context, ref, lease),
              onTerminate: () => _openTerminationApply(context, ref, lease),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestRenew(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认续租申请'),
        content: Text('确认对「${lease.houseName}」发起续租申请吗？'),
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
    final success = await controller.renew(lease.id);
    if (!context.mounted) return;
    final state = ref.read(leaseControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? state.actionMessage ?? '续租申请已提交'
              : state.errorMessage ?? '续租申请失败',
        ),
      ),
    );
    if (success) ref.invalidate(leaseDetailProvider(leaseId));
  }

  Future<void> _openTerminationApply(
    BuildContext context,
    WidgetRef ref,
    Lease lease,
  ) async {
    final current = await ref
        .read(leaseServiceProvider)
        .getCurrentTermination(lease.id);
    if (!context.mounted) return;
    if (current != null) {
      var shouldUploadInspection = false;
      if (lease.contractId.isNotEmpty) {
        try {
          final inspection = await ref
              .read(inspectionServiceProvider)
              .getMoveOutInspection(lease.contractId);
          shouldUploadInspection =
              inspection.status == MoveOutInspectionStatus.draft;
        } on Object {
          // 验收记录查询失败时，保留原有的已提交提示，不误导用户进入上传页。
        }
      }
      if (!context.mounted) return;
      final goUpload = await _showExistingTerminationDialog(
        context,
        current,
        canUploadInspection: shouldUploadInspection,
      );
      if (!context.mounted || !goUpload) return;
      context.pushNamed(
        RouteNames.moveOutInspection,
        pathParameters: {'leaseId': lease.id},
      );
      return;
    }
    context.pushNamed(
      RouteNames.leaseTerminationApply,
      pathParameters: {'leaseId': lease.id},
    );
  }

  Future<bool> _showExistingTerminationDialog(
    BuildContext context,
    TerminationApplication application, {
    required bool canUploadInspection,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(canUploadInspection ? '退租申请已提交' : '已有退租申请'),
        content: Text(
          canUploadInspection
              ? '退租申请（${application.applicationNo}）已提交，请继续上传退租验房照片。'
              : '当前租约已有退租申请（${application.applicationNo}），状态为${application.statusText}，请等待管家处理。',
        ),
        actions: [
          if (canUploadInspection)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('去上传'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(canUploadInspection ? '稍后上传' : '知道了'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _LeaseDetailContent extends ConsumerWidget {
  const _LeaseDetailContent({
    required this.lease,
    required this.onRenew,
    required this.onTerminate,
  });

  final Lease lease;
  final VoidCallback onRenew;
  final VoidCallback onTerminate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        108,
      ),
      children: [
        CurrentLeaseCard(
          lease: lease,
          onDetailTap: () {},
          onContractTap: () => _openContract(context, lease),
        ),
        if (lease.status == LeaseStatus.pending) ...[
          const SizedBox(height: AppSpacing.md),
          _PendingNoticeCard(effectiveDate: lease.startDate),
        ],
        if (lease.canOperate) ...[
          const SizedBox(height: AppSpacing.md),
          _SmartLockPermissionCard(leaseId: lease.id),
          const SizedBox(height: AppSpacing.md),
          _DepositEntry(leaseId: lease.id),
          const SizedBox(height: AppSpacing.md),
          LeaseActionGrid(
            isContractSigned:
                lease.contractStatus == LeaseContractStatus.signed,
            onContractTap: () => _openContract(context, lease),
            onBillTap: () => context.pushNamed(RouteNames.bill),
            onRenewTap: onRenew,
            onCheckoutTap: onTerminate,
          ),
          if (lease.pendingBillTitle.isNotEmpty ||
              lease.pendingBillAmount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            RentBillCard(
              title: lease.pendingBillTitle.isEmpty
                  ? '待支付账单'
                  : lease.pendingBillTitle,
              amount: lease.pendingBillAmount,
              dueDate: lease.pendingBillDueDate,
              onPayTap: () => context.pushNamed(RouteNames.bill),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
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
                  LeaseStatusBadge.forStatus(lease.status),
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
            ],
          ),
        ),
        if (lease.canOperate) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailCard(
            title: '更多服务',
            child: Column(
              children: [
                _ServiceButton(
                  icon: Icons.lock_clock_outlined,
                  label: '查看开锁记录',
                  onTap: () => context.pushNamed(RouteNames.unlockRecords),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _openContract(BuildContext context, Lease lease) {
    if (lease.contractStatus != LeaseContractStatus.signed) {
      context.pushNamed(RouteNames.rentOrders);
      return;
    }
    context.pushNamed(
      RouteNames.leaseContractView,
      pathParameters: {'leaseId': lease.id},
    );
  }
}

class _PendingNoticeCard extends StatelessWidget {
  const _PendingNoticeCard({required this.effectiveDate});

  final DateTime effectiveDate;

  @override
  Widget build(BuildContext context) {
    final month = effectiveDate.month;
    final day = effectiveDate.day;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '预计 $month月$day日 生效',
              style: AppTextStyles.bodyLarge.copyWith(
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

class _DepositEntry extends StatelessWidget {
  const _DepositEntry({required this.leaseId});

  final String leaseId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.pushNamed(
          RouteNames.depositDetail,
          pathParameters: {'leaseId': leaseId},
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '查看押金',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartLockPermissionCard extends ConsumerWidget {
  const _SmartLockPermissionCard({required this.leaseId});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockStatus = ref.watch(tenantLockStatusProvider(leaseId));
    return lockStatus.when(
      data: (data) => _SmartLockPermissionContent(
        status: _statusFromLockData(data),
        lockName: data.lockName,
      ),
      loading: () => const _SmartLockPermissionContent(
        title: '正在查询门锁状态',
        subtitle: '正在获取当前租约的门锁权限',
        statusLabel: '查询中',
        statusColor: AppColors.primary,
        icon: Icons.sync_rounded,
        showProgress: true,
      ),
      error: (error, _) => _SmartLockPermissionContent(
        title: _lockErrorTitle(error),
        subtitle: _lockErrorSubtitle(error),
        statusLabel: '不可用',
        statusColor: AppColors.warning,
        icon: Icons.lock_clock_rounded,
      ),
    );
  }

  static LeaseLockPermissionStatus _statusFromLockData(
    TenantLockUnlockData data,
  ) {
    // 租约失效优先判断
    if (data.isLeaseInvalid) return LeaseLockPermissionStatus.expired;
    return switch (data.permissionStatus.toUpperCase()) {
      'ACTIVE' => LeaseLockPermissionStatus.active,
      'EXPIRED' || 'LEASE_INVALID' => LeaseLockPermissionStatus.expired,
      'REVOKED' || 'DISABLED' => LeaseLockPermissionStatus.revoked,
      _ =>
        data.isActive
            ? LeaseLockPermissionStatus.active
            : LeaseLockPermissionStatus.revoked,
    };
  }

  static String _lockErrorTitle(Object error) {
    if (error is ApiException && error.statusCode == 404) {
      return '当前租约未绑定门锁';
    }
    if (error is ApiException && error.statusCode == 403) {
      return '暂无门锁权限';
    }
    return '门锁状态获取失败';
  }

  static String _lockErrorSubtitle(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return '请稍后刷新，或联系管家确认门锁状态';
  }
}

class _SmartLockPermissionContent extends StatelessWidget {
  const _SmartLockPermissionContent({
    this.status,
    this.lockName = '',
    this.title,
    this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.icon,
    this.showProgress = false,
  });

  final LeaseLockPermissionStatus? status;
  final String lockName;
  final String? title;
  final String? subtitle;
  final String? statusLabel;
  final Color? statusColor;
  final IconData? icon;
  final bool showProgress;

  String get _title =>
      title ??
      switch (status) {
        LeaseLockPermissionStatus.active => '智能门锁已经生效',
        LeaseLockPermissionStatus.expired => '智能门锁权限已过期',
        LeaseLockPermissionStatus.revoked => '智能门锁权限已回收',
        null => '门锁状态未知',
      };

  String get _subtitle =>
      subtitle ??
      switch (status) {
        LeaseLockPermissionStatus.active =>
          lockName.trim().isEmpty
              ? '可使用门锁开门权限，入住期间保持有效'
              : '$lockName 可使用，入住期间保持有效',
        LeaseLockPermissionStatus.expired => '当前门锁权限已过期，请联系管家处理',
        LeaseLockPermissionStatus.revoked => '当前门锁权限已回收，如需开门请联系管家',
        null => '请稍后刷新，或联系管家确认门锁状态',
      };

  String get _statusLabel =>
      statusLabel ??
      switch (status) {
        LeaseLockPermissionStatus.active => '有效',
        LeaseLockPermissionStatus.expired => '已过期',
        LeaseLockPermissionStatus.revoked => '已回收',
        null => '未知',
      };

  Color get _statusColor =>
      statusColor ??
      switch (status) {
        LeaseLockPermissionStatus.active => AppColors.success,
        LeaseLockPermissionStatus.expired => AppColors.warning,
        LeaseLockPermissionStatus.revoked => AppColors.error,
        null => AppColors.textMuted,
      };

  IconData get _icon =>
      icon ??
      switch (status) {
        LeaseLockPermissionStatus.active => Icons.lock_open_rounded,
        LeaseLockPermissionStatus.expired => Icons.lock_clock_rounded,
        LeaseLockPermissionStatus.revoked => Icons.lock_reset_rounded,
        null => Icons.lock_outline_rounded,
      };

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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: showProgress
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_icon, color: _statusColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              _statusLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

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
                color: AppColors.textPrimary,
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
