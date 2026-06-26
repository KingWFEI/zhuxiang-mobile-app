import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/lease.dart';
import 'lease_status_badge.dart';

class CurrentLeaseCard extends StatelessWidget {
  const CurrentLeaseCard({required this.lease, required this.onTap, super.key});

  final Lease lease;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: SizedBox(
                      width: 106,
                      height: 92,
                      child: lease.houseImageUrl.isEmpty
                          ? Image.asset('assets/home_bk.png', fit: BoxFit.cover)
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
                                lease.houseName,
                                style: AppTextStyles.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            LeaseStatusBadge(label: lease.status.label),
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
              Row(
                children: [
                  const Icon(
                    Icons.date_range_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('租期：', style: AppTextStyles.bodySmall),
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
              Row(
                children: [
                  Expanded(
                    child: _LeaseMetric(
                      label: '月租金',
                      value: '￥${formatLeaseMoney(lease.monthlyRent)} / 月',
                    ),
                  ),
                  Expanded(
                    child: _LeaseMetric(
                      label: '支付日',
                      value: '每月${lease.paymentDay}日',
                    ),
                  ),
                ],
              ),
            ],
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
                      lease.houseName,
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  LeaseStatusBadge(
                    label: lease.status.label,
                    color: AppColors.textSecondary,
                  ),
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

class _LeaseMetric extends StatelessWidget {
  const _LeaseMetric({required this.label, required this.value});

  final String label;
  final String value;

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
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String formatLeaseDate(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}

String formatLeaseMoney(int amount) {
  final yuan = amount >= 100000 ? amount / 100 : amount.toDouble();
  return yuan == yuan.roundToDouble()
      ? yuan.toInt().toString()
      : yuan.toStringAsFixed(2);
}
