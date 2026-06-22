import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/unlock_record.dart';

class UnlockRecordItem extends StatelessWidget {
  const UnlockRecordItem({
    required this.record,
    required this.onTap,
    super.key,
  });

  final UnlockRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final success = record.isSuccess;
    final statusColor = success ? AppColors.success : AppColors.error;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlockMethodIcon(record.unlockMethod),
                  color: statusColor,
                  size: 22,
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
                            record.unlockMethod.label,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          record.unlockResult.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatRecordDateTime(record.unlockTime),
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${record.houseName} · ${record.lockName}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      record.operatorType.label,
                      style: AppTextStyles.bodySmall,
                    ),
                    if (!success && record.failureReason.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          record.failureReason,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

IconData unlockMethodIcon(UnlockMethod method) {
  return switch (method) {
    UnlockMethod.bluetooth => Icons.bluetooth_rounded,
    UnlockMethod.remote => Icons.wifi_tethering_rounded,
    UnlockMethod.password => Icons.password_rounded,
    UnlockMethod.admin => Icons.admin_panel_settings_outlined,
    UnlockMethod.system => Icons.settings_suggest_outlined,
  };
}

String formatRecordDateTime(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
