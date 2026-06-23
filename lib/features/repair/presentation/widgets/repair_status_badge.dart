import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/repair_order.dart';

class RepairStatusBadge extends StatelessWidget {
  const RepairStatusBadge({required this.status, super.key});

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RepairStatus.submitted => AppColors.warning,
      RepairStatus.accepted => AppColors.primary,
      RepairStatus.assigned => AppColors.primary,
      RepairStatus.processing => AppColors.primary,
      RepairStatus.pendingReview => const Color(0xFF7667F8),
      RepairStatus.completed => AppColors.success,
      RepairStatus.cancelled => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
