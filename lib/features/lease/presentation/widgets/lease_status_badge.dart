import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/lease.dart';

class LeaseStatusBadge extends StatelessWidget {
  const LeaseStatusBadge({
    required this.label,
    super.key,
    this.color,
  });

  factory LeaseStatusBadge.forStatus(LeaseStatus status) {
    return LeaseStatusBadge(
      label: status.label,
      color: status.color,
    );
  }

  final String label;
  final Color? color;

  Color get _effectiveColor => color ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: _effectiveColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
