import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/hot_community.dart';

/// 搜索页顶部输入区，包含返回、清除和搜索/取消操作。
class SearchInputHeader extends StatelessWidget {
  const SearchInputHeader({
    required this.controller,
    required this.onBack,
    required this.onChanged,
    required this.onSubmitted,
    required this.onAction,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
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
            child: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
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
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.iconMuted,
                  size: 20,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        color: AppColors.textMuted,
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(
            controller.text.isEmpty ? '取消' : '搜索',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// 搜索历史区域，点击词条直接执行搜索。
class SearchHistorySection extends StatelessWidget {
  const SearchHistorySection({
    required this.items,
    required this.onItemTap,
    required this.onClear,
    super.key,
  });

  final List<String> items;
  final ValueChanged<String> onItemTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '搜索历史',
          trailing: IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            color: AppColors.iconMuted,
            visualDensity: VisualDensity.compact,
          ),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items
              .map(
                (item) => GestureDetector(
                  onTap: () => onItemTap(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface, // 白色背景
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

/// 热门搜索快捷入口。
class HotSearchSection extends StatelessWidget {
  const HotSearchSection({required this.onItemTap, super.key});

  final ValueChanged<String> onItemTap;

  static const _items = <(String, IconData, Color)>[
    ('近地铁', Icons.directions_subway_rounded, Color(0xFF438CF6)),
    ('整租', Icons.home_rounded, Color(0xFF4D8EF7)),
    ('两居室', Icons.weekend_rounded, Color(0xFF8C67E8)),
    ('可月付', Icons.calendar_month_rounded, Color(0xFF35B98F)),
    ('智能门锁', Icons.lock_rounded, Color(0xFFF29B38)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '热门搜索'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var index = 0; index < _items.length; index++) ...[
              Expanded(
                child: _HotSearchCard(
                  label: _items[index].$1,
                  icon: _items[index].$2,
                  color: _items[index].$3,
                  onTap: () => onItemTap(_items[index].$1),
                ),
              ),
              if (index != _items.length - 1)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _HotSearchCard extends StatelessWidget {
  const _HotSearchCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 横向热门小区卡片列表，数据由 HouseService 提供。
class HotCommunitySection extends StatelessWidget {
  const HotCommunitySection({
    required this.communities,
    required this.onItemTap,
    super.key,
  });

  final List<HotCommunity> communities;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '热门小区', trailingText: '查看更多 ›'),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < communities.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  _CommunityCard(
                    community: communities[i],
                    onTap: () => onItemTap(communities[i].name),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community, required this.onTap});

  final HotCommunity community;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          width: 106,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Color(community.colorValue),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      community.district,
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¥ ${community.startingRent} 起',
                      style: TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 根据当前输入展示关键词组合建议，不展示房源列表。
class SearchSuggestionSection extends StatelessWidget {
  const SearchSuggestionSection({
    required this.keyword,
    required this.onItemTap,
    super.key,
  });

  final String keyword;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return const SizedBox.shrink();
    final suffixes = ['近地铁', '两居室 整租', '可月付', '智能门锁'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: '搜索建议'),
        for (final suffix in suffixes)
          InkWell(
            onTap: () => onItemTap(normalized),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.iconMuted,
                    size: 12,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    normalized,
                    style: TextStyle(fontSize: 10, color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      suffix,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({this.title, this.trailing, this.trailingText});

  final String? title;
  final Widget? trailing;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title ?? '',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 33, 34, 34),
          ),
        ),
        const Spacer(),
        ?trailing,
        if (trailingText != null)
          Text(
            trailingText!,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}
