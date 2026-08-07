import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// 五项筛选栏：区域 | 租金 | 户型 | 排序 | 更多
class HouseFilterBar extends StatelessWidget {
  const HouseFilterBar({
    required this.region,
    required this.minPrice,
    required this.maxPrice,
    required this.roomType,
    required this.sort,
    required this.moreActive,
    required this.onRegionTap,
    required this.onRentTap,
    required this.onRoomTap,
    required this.onSortTap,
    required this.onMoreTap,
    super.key,
  });

  final String region;
  final int minPrice;
  final int maxPrice;
  final String roomType;
  final String sort;
  final bool moreActive;
  final VoidCallback onRegionTap;
  final VoidCallback onRentTap;
  final VoidCallback onRoomTap;
  final VoidCallback onSortTap;
  final VoidCallback onMoreTap;

  String get _regionLabel {
    return switch (region) {
      'yubei' => '渝北',
      'jiangbei' => '江北',
      'yuzhong' => '渝中',
      _ when region.isNotEmpty => region,
      _ => '区域',
    };
  }

  String get _rentLabel {
    if (minPrice <= 0 && maxPrice <= 0) return '租金';
    final min = minPrice >= 100 ? '¥${(minPrice / 100).round()}' : '¥$minPrice';
    final max = maxPrice > 0
        ? (maxPrice >= 100 ? '${(maxPrice / 100).round()}' : '$maxPrice')
        : '不限';
    return '$min-$max';
  }

  String get _roomLabel {
    return switch (roomType) {
      '1室0厅1卫' => '单间',
      '1室1厅1卫' => '一室',
      '2室1厅1卫' => '两室',
      '3室1厅1卫' => '三室',
      _ when roomType.isNotEmpty => roomType,
      _ => '户型',
    };
  }

  String get _sortLabel {
    return switch (sort) {
      'price_asc' => '低价',
      'price_desc' => '高价',
      'distance' => '距离',
      'latest' => '最新',
      'smart_lock' => '智能锁',
      _ => '排序',
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = <(String label, bool active, VoidCallback onTap)>[
      (_regionLabel, region.isNotEmpty, onRegionTap),
      (_rentLabel, minPrice > 0 || maxPrice > 0, onRentTap),
      (_roomLabel, roomType.isNotEmpty, onRoomTap),
      (_sortLabel, sort.isNotEmpty && sort != 'default', onSortTap),
      ('更多', moreActive, onMoreTap),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: _FilterButton(
                index: index,
                label: items[index].$1,
                active: items[index].$2,
                onTap: items[index].$3,
              ),
            ),
            if (index != items.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.index,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final VoidCallback onTap;

  List<List<dynamic>> get _icon => switch (index) {
    0 => HugeIcons.strokeRoundedLocation01,
    1 => HugeIcons.strokeRoundedMoney01,
    2 => HugeIcons.strokeRoundedHome01,
    3 => HugeIcons.strokeRoundedSorting05,
    _ => HugeIcons.strokeRoundedGridView,
  };

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HugeIcon(icon: _icon, color: color, size: 22),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Icon(
                    Icons.arrow_drop_down,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
