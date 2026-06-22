import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// 五项筛选栏，使用等分布局保证小屏也能在一行完整展示。
class HouseFilterBar extends StatelessWidget {
  const HouseFilterBar({
    required this.onRegionTap,
    required this.onRentTap,
    required this.onRoomTap,
    required this.onMoreTap,
    required this.onSortTap,
    super.key,
  });

  final VoidCallback onRegionTap;
  final VoidCallback onRentTap;
  final VoidCallback onRoomTap;
  final VoidCallback onMoreTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final items = <(String, VoidCallback)>[
      ('区域', onRegionTap),
      ('租金', onRentTap),
      ('户型', onRoomTap),
      ('更多', onMoreTap),
      ('排序', onSortTap),
    ];
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(
            child: _FilterButton(
              label: items[index].$1,
              onTap: items[index].$2,
            ),
          ),
          if (index != items.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
