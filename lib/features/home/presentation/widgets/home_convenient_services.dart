import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'home_service_entry.dart';

class HomeConvenientServices extends StatelessWidget {
  const HomeConvenientServices({
    required this.onLeaseTap,
    required this.onDoorRecordTap,
    required this.onRepairTap,
    required this.onCustomerServiceTap,
    super.key,
  });

  final VoidCallback onLeaseTap;
  final VoidCallback onDoorRecordTap;
  final VoidCallback onRepairTap;
  final VoidCallback onCustomerServiceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('便捷服务', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: HomeServiceEntry(
                  icon: Icons.description_rounded,
                  label: '我的租约',
                  color: AppColors.primary,
                  onTap: onLeaseTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeServiceEntry(
                  icon: Icons.history_rounded,
                  label: '开门记录',
                  color: AppColors.secondary,
                  onTap: onDoorRecordTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeServiceEntry(
                  icon: Icons.home_repair_service_rounded,
                  label: '报修服务',
                  color: AppColors.warning,
                  onTap: onRepairTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: HomeServiceEntry(
                  icon: Icons.support_agent_rounded,
                  label: '在线客服',
                  color: Color(0xFF7667F8),
                  onTap: onCustomerServiceTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
