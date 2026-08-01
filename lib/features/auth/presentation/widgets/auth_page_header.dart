import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.primaryLight],
              ),
            ),
          ),
          Positioned(
            right: -52,
            bottom: -46,
            child: Icon(
              Icons.apartment_rounded,
              size: 188,
              color: AppColors.primarySoft.withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandMark(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 26,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.home_work, color: AppColors.primary, size: 18),
        const SizedBox(width: 2),
        Text('勿忧管家', style: AppTextStyles.logoTitle),
      ],
    );
  }
}
