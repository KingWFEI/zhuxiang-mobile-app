import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
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
      height: 360,
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
          const Positioned(
            right: -4,
            top: 42,
            bottom: 0,
            child: _HeaderIllustration(),
          ),
          Positioned(
            left: AppSpacing.xxl,
            top: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandMark(),
                const SizedBox(height: 96),
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 34,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 17,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: const Icon(Icons.home, color: AppColors.primary, size: 32),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '住享',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 94,
              decoration: const BoxDecoration(color: AppColors.primarySoft),
            ),
          ),
          Positioned(
            right: 64,
            top: 48,
            child: Container(
              width: 108,
              height: 176,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surface),
              ),
              child: GridView.count(
                padding: const EdgeInsets.all(AppSpacing.md),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  6,
                  (_) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 128,
            child: Container(
              width: 58,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.lock, color: AppColors.surface, size: 22),
            ),
          ),
          Positioned(
            right: 0,
            top: 200,
            child: Container(
              width: 104,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 120,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.location_on,
                color: AppColors.surface,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
