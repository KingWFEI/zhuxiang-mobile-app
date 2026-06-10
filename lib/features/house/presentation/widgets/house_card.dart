import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/house.dart';
import 'house_image_placeholder.dart';

class HouseCard extends StatelessWidget {
  const HouseCard({
    required this.house,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final House house;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
        child: compact
            ? _CompactContent(house: house)
            : _ListContent(house: house),
      ),
    );
  }
}

class _ListContent extends StatelessWidget {
  const _ListContent({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: const SizedBox(
            width: 150,
            height: 132,
            child: HouseImagePlaceholder(),
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
                      house.title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    house.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: house.isFavorite
                        ? AppColors.error
                        : AppColors.iconMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: house.tags
                    .take(3)
                    .map((tag) => _HouseTag(tag))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${house.roomType}  |  ${house.area}m²  |  ${house.floor}',
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                house.metro,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  text: '¥ ${house.price}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 22,
                  ),
                  children: [
                    TextSpan(text: ' /月', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HouseImagePlaceholder(height: 112),
        const SizedBox(height: AppSpacing.sm),
        Text(
          house.title,
          style: AppTextStyles.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${house.roomType}  |  ${house.area}m²  |  ${house.orientation}',
          style: AppTextStyles.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            text: '¥ ${house.price}',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            children: [TextSpan(text: ' /月', style: AppTextStyles.bodyMedium)],
          ),
        ),
      ],
    );
  }
}

class _HouseTag extends StatelessWidget {
  const _HouseTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
