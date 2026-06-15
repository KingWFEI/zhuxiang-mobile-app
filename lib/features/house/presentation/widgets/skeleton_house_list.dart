import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class SkeletonHouseList extends StatelessWidget {
  const SkeletonHouseList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const _SkeletonHouseCard(),
    );
  }
}

class _SkeletonHouseCard extends StatelessWidget {
  const _SkeletonHouseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Row(
        children: [
          _SkeletonBox(width: 150, height: double.infinity),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 20),
                SizedBox(height: AppSpacing.md),
                _SkeletonBox(width: 110, height: 18),
                SizedBox(height: AppSpacing.sm),
                _SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: AppSpacing.sm),
                _SkeletonBox(width: 130, height: 14),
                Spacer(),
                _SkeletonBox(width: 90, height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
