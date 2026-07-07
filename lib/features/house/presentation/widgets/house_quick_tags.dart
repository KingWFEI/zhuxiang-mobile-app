import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HouseQuickTags extends StatelessWidget {
  const HouseQuickTags({
    required this.tags,
    required this.selectedTags,
    required this.onTagTap,
    super.key,
  });

  final List<QuickTagItem> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = selectedTags.contains(tag.value);

          return _QuickTagChip(
            label: tag.label,
            isSelected: isSelected,
            onTap: () => onTagTap(tag.value),
          );
        },
      ),
    );
  }
}

class QuickTagItem {
  const QuickTagItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _QuickTagChip extends StatelessWidget {
  const _QuickTagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.12)
        : const Color(0xFFF6F9FF);

    final Color borderColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.35)
        : const Color(0xFFEAF0FA);

    final Color textColor = isSelected
        ? AppColors.primary
        : const Color(0xFF5D6B82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
