import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/house.dart';
import 'house_image_placeholder.dart';

class HouseCard extends StatelessWidget {
  const HouseCard({
    required this.house,
    this.onTap,
    super.key,
    this.compact = false,
    this.isFavorite,
    this.onFavoriteTap,
  });

  final House house;
  final VoidCallback? onTap;
  final bool compact;
  final bool? isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    const radius = AppRadius.xl;
    return InkWell(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      onTap: onTap,
      child: Container(
        // padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
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
            : _ListContent(
                house: house,
                isFavorite: isFavorite ?? house.isFavorite,
                onFavoriteTap: onFavoriteTap,
              ),
      ),
    );
  }
}

class _ListContent extends StatelessWidget {
  const _ListContent({
    required this.house,
    required this.isFavorite,
    this.onFavoriteTap,
  });

  final House house;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        // 卡片整体高度
        final cardHeight = isNarrow ? 112.0 : 104.0;

        // 卡片内部 padding
        const padding = 4.0;

        // 内容区域高度 = 卡片高度 - 上下 padding
        final contentHeight = cardHeight - padding * 2;

        // 图片高度占满内容高度
        final imageHeight = contentHeight;

        // 图片宽度按照高度的 1.5 倍
        final imageWidth = imageHeight * 1.35;

        return SizedBox(
          height: cardHeight,
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: _HouseCover(
                    house: house,
                    width: imageWidth,
                    height: imageHeight,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: contentHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                house.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkResponse(
                              onTap: onFavoriteTap,
                              radius: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite
                                      ? AppColors.error
                                      : const Color(0xFF718096),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${house.location} · ${house.community}  ${house.metro}',
                          style: const TextStyle(
                            color: Color(0xFF76839A),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${house.roomType}  |  ${house.area}m²  |  ${house.orientation}  |  ${house.floor}',
                          style: const TextStyle(
                            color: Color(0xFF7F8A9E),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: house.tags
                              .take(isNarrow ? 2 : 3)
                              .map((tag) => _HouseTag(tag, dense: true))
                              .toList(growable: false),
                        ),
                        const Spacer(),
                        Text.rich(
                          TextSpan(
                            text: '¥ ${_displayPrice(house.price)}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            children: const [
                              TextSpan(
                                text: ' /月',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _HouseAction extends StatelessWidget {
  const _HouseAction({required this.house, required this.onTap});

  final House house;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reserved =
        house.status.toLowerCase() == 'reserved' ||
        house.rentAvailability.toLowerCase() == 'reserved';
    if (!reserved) {
      return _ActionButton(label: '立即租用', onTap: onTap);
    }
    if (house.activeOrderBelongsToMe) {
      return _ActionButton(
        label: '继续办理',
        onTap: onTap,
        color: AppColors.success,
      );
    }
    return const _ActionButton(label: '已被预定');
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          minimumSize: const Size(0, 26),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
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
        _HouseCover(house: house, height: 120),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                house.title,
                style: AppTextStyles.houseCardH1,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${house.roomType} | ${house.area}m² | ${house.orientation}',
                style: AppTextStyles.houseCardH2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: house.tags
                    .take(2)
                    .map((tag) => _HouseTag(tag))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  text: '¥ ${_displayPrice(house.price)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: ' /月',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
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

class _HouseCover extends StatelessWidget {
  const _HouseCover({required this.house, required this.height, this.width});

  final House house;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HouseImagePlaceholder(coverImage: house.coverImage, height: height),
          if (house.isRentLocked)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xE63A3F4B),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text(
                  '办理中',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            child: _HouseSourceBadge(
              label: house.sourceLabel,
              isPlatform: house.isPlatformSource,
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseSourceBadge extends StatelessWidget {
  const _HouseSourceBadge({required this.label, required this.isPlatform});

  final String label;
  final bool isPlatform;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isPlatform ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _displayPrice(int price) {
  if (price < 10000) return '$price';
  final value = price / 100;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class _HouseTag extends StatelessWidget {
  const _HouseTag(this.label, {this.dense = false});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
