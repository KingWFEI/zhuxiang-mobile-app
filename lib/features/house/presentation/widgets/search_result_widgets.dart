import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// 搜索结果页顶部栏，与搜索页 SearchInputHeader 保持一致的视觉风格。
class SearchResultHeader extends StatefulWidget {
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
  State<SearchResultHeader> createState() => _SearchResultHeaderState();
}

class _SearchResultHeaderState extends State<SearchResultHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.keyword);
  }

  @override
  void didUpdateWidget(covariant SearchResultHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword) {
      _controller.text = widget.keyword;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onBack,
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 44),
            maximumSize: const Size(32, 44),
            alignment: Alignment.centerLeft,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SizedBox(
            height: 34,
            child: GestureDetector(
              onTap: widget.onSearchTap,
              child: TextField(
                controller: _controller,
                enabled: false,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '搜索小区、地铁、区域或房源',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.iconMuted,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    onPressed: widget.onClear,
                    icon: const Icon(Icons.cancel, size: 18),
                    color: AppColors.textMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: widget.onFilterTap,
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
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
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
                Icon(item.$2, color: item.$3, size: 14),
                const SizedBox(width: AppSpacing.sm),
                Text(item.$1, style: TextStyle(fontSize: 10)),
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
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sortText,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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
