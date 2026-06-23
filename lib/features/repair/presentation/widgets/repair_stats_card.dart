import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class RepairStatsCard extends StatelessWidget {
  const RepairStatsCard({
    required this.pendingCount,
    required this.processingCount,
    required this.pendingReviewCount,
    required this.completedCount,
    super.key,
  });

  final int pendingCount;
  final int processingCount;
  final int pendingReviewCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _StatItem(
            label: '待处理',
            count: pendingCount,
            color: AppColors.warning,
          ),
          _StatItem(
            label: '处理中',
            count: processingCount,
            color: AppColors.primary,
          ),
          _StatItem(
            label: '待评价',
            count: pendingReviewCount,
            color: const Color(0xFF7667F8),
          ),
          _StatItem(
            label: '已完成',
            count: completedCount,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
