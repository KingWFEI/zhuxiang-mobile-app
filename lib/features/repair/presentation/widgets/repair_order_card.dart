import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/repair_order.dart';
import 'repair_status_badge.dart';

class RepairOrderCard extends StatelessWidget {
  const RepairOrderCard({
    required this.order,
    required this.onTap,
    this.onReview,
    super.key,
  });

  final RepairOrder order;
  final VoidCallback onTap;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final latest = order.timeline.isNotEmpty ? order.timeline.last : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    _iconFor(order.repairType),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.repairTypeText,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        order.houseName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                RepairStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(order.summary, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatRepairDateTime(order.createdAt)} · ${order.housekeeperName}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (order.status.canReview && onReview != null)
                  TextButton(onPressed: onReview, child: const Text('去评价'))
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.iconMuted,
                  ),
              ],
            ),
            if (latest != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  '最新进度：${latest.title} · ${latest.description}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(RepairType type) => switch (type) {
    RepairType.plumbing => Icons.water_drop_rounded,
    RepairType.electrical => Icons.electric_bolt_rounded,
    RepairType.appliance => Icons.kitchen_rounded,
    RepairType.lock => Icons.lock_rounded,
    RepairType.furniture => Icons.chair_rounded,
    RepairType.network => Icons.wifi_rounded,
    RepairType.other => Icons.build_circle_rounded,
  };
}

String formatRepairDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
}
