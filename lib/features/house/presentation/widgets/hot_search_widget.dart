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
              Text('搜索历史', style: AppTextStyles.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearHistory,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('清空'),
              ),
            ],
          ),
          _KeywordWrap(keywords: history, onKeywordTap: onKeywordTap),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('热门搜索', style: AppTextStyles.titleMedium),
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
              label: Text(keyword),
              onPressed: () => onKeywordTap(keyword),
              side: BorderSide.none,
              backgroundColor: AppColors.surface,
            ),
          )
          .toList(growable: false),
    );
  }
}
