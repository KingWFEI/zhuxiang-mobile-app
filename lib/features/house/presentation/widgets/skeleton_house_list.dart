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
      height: 104,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图占位：w = 96*1.35 ≈ 130, h = 96
          const _SkeletonBox(width: 130, height: 96),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行：标题 + 收藏心形
                  const Row(
                    children: [
                      Expanded(
                          child: _SkeletonBox(
                              width: double.infinity, height: 12)),
                      SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 18, height: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 位置信息
                  const _SkeletonBox(width: 180, height: 8),
                  const SizedBox(height: 4),
                  // 户型 / 面积 / 朝向
                  const _SkeletonBox(width: 160, height: 8),
                  const SizedBox(height: 6),
                  // 标签（3个）
                  const Row(
                    children: [
                      _SkeletonBox(width: 52, height: 18),
                      SizedBox(width: 5),
                      _SkeletonBox(width: 44, height: 18),
                      SizedBox(width: 5),
                      _SkeletonBox(width: 38, height: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 价格
                  const _SkeletonBox(width: 80, height: 16),
                ],
              ),
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
