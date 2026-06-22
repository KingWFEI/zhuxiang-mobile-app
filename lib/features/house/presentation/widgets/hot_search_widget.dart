import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class SearchDiscoverySection extends StatelessWidget {
  const SearchDiscoverySection({
    required this.history,
    required this.hotKeywords,
    required this.onKeywordTap,
    required this.onClearHistory,
    super.key,
  });

  final List<String> history;
  final List<String> hotKeywords;
  final ValueChanged<String> onKeywordTap;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (history.isNotEmpty) ...[
          Row(
            children: [
              Text(
                '搜索历史',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearHistory,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  textStyle: AppTextStyles.bodySmall,
                ),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('清空'),
              ),
            ],
          ),
          _KeywordWrap(keywords: history, onKeywordTap: onKeywordTap),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              color: AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '热门搜索',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _KeywordWrap(keywords: hotKeywords, onKeywordTap: onKeywordTap),
      ],
    );
  }
}

class _KeywordWrap extends StatelessWidget {
  const _KeywordWrap({required this.keywords, required this.onKeywordTap});

  final List<String> keywords;
  final ValueChanged<String> onKeywordTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: keywords
          .map(
            (keyword) => ActionChip(
              label: Text(keyword, style: AppTextStyles.bodySmall),
              onPressed: () => onKeywordTap(keyword),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ),
              side: BorderSide.none,
              backgroundColor: AppColors.surface,
            ),
          )
          .toList(growable: false),
    );
  }
}
