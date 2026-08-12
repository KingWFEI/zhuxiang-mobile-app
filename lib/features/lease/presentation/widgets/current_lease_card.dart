import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/lease.dart';
import 'lease_status_badge.dart';

class CurrentLeaseCard extends StatelessWidget {
  const CurrentLeaseCard({
    required this.lease,
    required this.onDetailTap,
    required this.onContractTap,
    this.onKeeperTap,
    this.onPayTap,
    super.key,
  });

  final Lease lease;
  final VoidCallback onDetailTap;
  final VoidCallback onContractTap;
  final VoidCallback? onKeeperTap;
  final VoidCallback? onPayTap;

  bool get _needsAction =>
      lease.status == LeaseStatus.pending ||
      lease.billStatus == LeaseBillStatus.unpaid ||
      lease.billStatus == LeaseBillStatus.overdue;

  Color get _accentColor =>
      _needsAction ? AppColors.warning : AppColors.primary;

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
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        lease.houseSummary,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
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
            // ── 租期 ──
            Row(
              children: [
                Icon(Icons.date_range_outlined, size: 18, color: _accentColor),
                const SizedBox(width: AppSpacing.sm),
                Text('租期', style: AppTextStyles.bodySmall),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${formatLeaseDate(lease.startDate)} - ${formatLeaseDate(lease.endDate)}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // ── 租金 & 支付日 ──
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: '月租金',
                    value: '¥${formatLeaseMoney(lease.monthlyRent)}',
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(width: 1, height: 32, color: AppColors.border),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Metric(
                    label: '支付日',
                    value: '每月${lease.paymentDay}日',
                    color: _accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── 操作按钮 ──
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '查看详情',
                    onTap: onDetailTap,
                    accentColor: _accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionButton(
                    label: '查看合同',
                    onTap: onContractTap,
                    accentColor: _accentColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _needsAction
                      ? _ActionButton(
                          label: '去支付',
                          onTap: onPayTap ?? () {},
                          primary: true,
                          accentColor: _accentColor,
                        )
                      : _ActionButton(
                          label: '联系管家',
                          onTap: onKeeperTap ?? () {},
                          accentColor: _accentColor,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.accentColor,
    this.primary = false,
  });
  final String label;
  final VoidCallback onTap;
  final Color accentColor;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final borderColor = primary ? accentColor : AppColors.border;
    final textColor = primary ? accentColor : AppColors.textSecondary;
    final bgColor = primary ? accentColor.withValues(alpha: 0.08) : Colors.transparent;

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HistoryLeaseCard extends StatelessWidget {
  const HistoryLeaseCard({required this.lease, required this.onTap, super.key});

  final Lease lease;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      roomLabel(lease.houseName),
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  LeaseStatusBadge.forStatus(lease.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${formatLeaseDate(lease.startDate)} - ${formatLeaseDate(lease.endDate)}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '合同状态：${lease.contractStatus.label}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('查看详情'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String roomLabel(String houseName) {
  final idx = houseName.indexOf('栋');
  if (idx == -1) return houseName;
  var start = idx;
  while (start > 0 && houseName[start - 1] != ' ') {
    start--;
  }
  return houseName.substring(start);
}

String formatLeaseDate(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}

String formatLeaseMoney(int amount) {
  final yuan = amount / 100;
  return yuan == yuan.roundToDouble()
      ? yuan.toInt().toString()
      : yuan.toStringAsFixed(2);
}
