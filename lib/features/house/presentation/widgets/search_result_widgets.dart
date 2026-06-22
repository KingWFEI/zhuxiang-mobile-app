import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// 搜索结果页顶部栏，显示当前关键词和筛选入口。
class SearchResultHeader extends StatelessWidget {
  const SearchResultHeader({
    required this.keyword,
    required this.onBack,
    required this.onSearchTap,
    required this.onClear,
    required this.onFilterTap,
    super.key,
  });

  final String keyword;
  final VoidCallback onBack;
  final VoidCallback onSearchTap;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.iconMuted,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        keyword.isEmpty ? '搜索房源' : keyword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.cancel, size: 18),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: onFilterTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          icon: const Icon(Icons.filter_alt_outlined, size: 20),
          label: const Text('筛选'),
        ),
      ],
    );
  }
}

/// 搜索结果页的横向快捷条件。
class SearchResultQuickConditions extends StatelessWidget {
  const SearchResultQuickConditions({required this.onTap, super.key});

  final ValueChanged<String> onTap;

  static const _items = <(String, IconData, Color)>[
    ('近地铁', Icons.directions_subway_rounded, Color(0xFF438CF6)),
    ('可月付', Icons.calendar_month_rounded, Color(0xFF35B98F)),
    ('智能门锁', Icons.lock_outline_rounded, Color(0xFFF29B38)),
    ('更多条件', Icons.more_horiz_rounded, Color(0xFF4D8EF7)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _items.length,
        separatorBuilder: (_, _) => Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: AppColors.border,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          return InkWell(
            onTap: () => onTap(item.$1),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: item.$3.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.$2, color: item.$3, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(item.$1, style: AppTextStyles.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 首页和结果页共用的房源数量、排序标题行。
class HouseListHeader extends StatelessWidget {
  const HouseListHeader({
    required this.countText,
    required this.sortText,
    required this.onSortTap,
    super.key,
  });

  final String countText;
  final String sortText;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '共找到 ',
              style: AppTextStyles.bodyMedium,
              children: [
                TextSpan(
                  text: countText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' 套房源'),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: onSortTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sortText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
