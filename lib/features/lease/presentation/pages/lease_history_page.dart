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
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../application/lease_controller.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/lease.dart';
import '../widgets/current_lease_card.dart';
import '../widgets/lease_empty_view.dart';
import '../widgets/lease_status_badge.dart';

class LeaseHistoryPage extends ConsumerStatefulWidget {
  const LeaseHistoryPage({super.key});

  @override
  ConsumerState<LeaseHistoryPage> createState() => _LeaseHistoryPageState();
}

class _LeaseHistoryPageState extends ConsumerState<LeaseHistoryPage> {
  LeaseStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(leaseControllerProvider.notifier).load();
    });
  }

  List<Lease> _filtered(List<Lease> leases) {
    if (_statusFilter == null) return leases;
    return leases.where((l) => l.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final leaseState = ref.watch(leaseControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const _HistoryHeader(),
                const _InfoBanner(),
                _StatusFilterBar(
                  selected: _statusFilter,
                  onChanged: (s) => setState(() => _statusFilter = s),
                ),
                Expanded(
                  child: _buildContent(leaseState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LeaseState state) {
    if (state.isLoading && state.leases.isEmpty) {
      return const SizedBox(
        height: 360,
        child: AppLoadingView(message: '正在加载历史租约'),
      );
    }
    if (state.errorMessage != null && state.leases.isEmpty) {
      return SizedBox(
        height: 360,
        child: AppErrorView(
          message: state.errorMessage!,
          onRetry: ref.read(leaseControllerProvider.notifier).load,
        ),
      );
    }

    final filtered = _filtered(state.historyLeases);

    if (filtered.isEmpty) {
      return const LeaseEmptyView(message: '暂无历史租约记录');
    }

    return RefreshIndicator(
      onRefresh: ref.read(leaseControllerProvider.notifier).load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.lg,
          AppSpacing.pageHorizontal,
          108,
        ),
        children: [
          for (final lease in filtered) ...[
            _HistoryLeaseCard(lease: lease),
            const SizedBox(height: AppSpacing.xl),
          ],
          const _EndNotice(),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

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
            const SizedBox(
              width: 72,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BackButton(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '历史租约',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(
              width: 72,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: AppIcon.iconBack,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '仅展示已结束的租约记录',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // dismiss banner
            },
            child: const Icon(Icons.close, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final LeaseStatus? selected;
  final ValueChanged<LeaseStatus?> onChanged;

  static const _statuses = [
    (null, '全部'),
    (LeaseStatus.expired, '已到期'),
    (LeaseStatus.checkedOut, '已退租'),
    (LeaseStatus.cancelled, '已取消'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _statuses.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final (status, label) = _statuses[index];
            final isSelected = selected == status;
            return SizedBox(
              height: 36,
              child: ChoiceChip(
                selected: isSelected,
                label: Text(label),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.primaryLight,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onChanged(status),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryLeaseCard extends StatelessWidget {
  const _HistoryLeaseCard({required this.lease});

  final Lease lease;

  bool get _depositReturned =>
      lease.status == LeaseStatus.checkedOut ||
      lease.status == LeaseStatus.expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 房源信息 ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: SizedBox(
                    width: 80,
                    height: 68,
                    child: lease.houseImageUrl.isEmpty
                        ? Image.asset(
                            'assets/home_bk.png',
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            lease.houseImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/home_bk.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              roomLabel(lease.houseName),
                              style: AppTextStyles.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          LeaseStatusBadge.forStatus(lease.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lease.houseSummary,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.iconMuted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              lease.houseAddress,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            // ── 租期 / 月租金 / 押金 三列 ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HistoryMetric(
                    label: '租期',
                    value: '${formatLeaseDate(lease.startDate)}\n— ${formatLeaseDate(lease.endDate)}',
                  ),
                ),
                Container(width: 1, height: 42, color: AppColors.border),
                Expanded(
                  child: _HistoryMetric(
                    label: '月租金',
                    value: '¥${formatLeaseMoney(lease.monthlyRent)}/月',
                  ),
                ),
                Container(width: 1, height: 42, color: AppColors.border),
                Expanded(
                  child: _HistoryMetric(
                    label: '押金',
                    value: '¥${formatLeaseMoney(lease.deposit)}',
                    trailing: _depositReturned
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '已退还',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            // ── 操作按钮 ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TextIconButton(
                  icon: Icons.description_outlined,
                  label: '查看合同',
                  onTap: () => _openContract(context, lease),
                ),
                _TextIconButton(
                  icon: Icons.receipt_long_outlined,
                  label: '费用明细',
                  onTap: () => _openBill(context),
                ),
              ],
            ),
          ],
        ),
      ),
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

  void _openBill(BuildContext context) {
    context.pushNamed(RouteNames.bill);
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _TextIconButton extends StatelessWidget {
  const _TextIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndNotice extends StatelessWidget {
  const _EndNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.lg),
      child: Center(
        child: Text(
          '没有更多了',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

