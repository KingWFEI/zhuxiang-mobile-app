import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class HomeServiceEntry extends StatelessWidget {
  const HomeServiceEntry({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
    this.onTap,
    this.subtitle,
    this.forceMonochrome = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool forceMonochrome;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          // horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        // decoration: BoxDecoration(
        //   color: AppColors.surface,
        //   borderRadius: BorderRadius.circular(AppRadius.lg),
        //   border: Border.all(color: AppColors.border),
        // ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              color: forceMonochrome ? AppColors.textPrimary : color,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
