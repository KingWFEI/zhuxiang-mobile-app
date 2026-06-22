import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HouseQuickTags extends StatelessWidget {
  const HouseQuickTags({
    required this.selectedTags,
    required this.onTagTap,
    super.key,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onTagTap;

  static const List<_QuickTagItem> _tags = [
    _QuickTagItem(label: '近地铁', icon: Icons.train_rounded),
    _QuickTagItem(label: '整租', icon: Icons.apartment_rounded),
    _QuickTagItem(label: '可月付', icon: Icons.event_available_rounded),
    _QuickTagItem(label: '智能门锁', icon: Icons.lock_outline_rounded),
    _QuickTagItem(label: '拎包入住', icon: Icons.inventory_2_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isSelected = selectedTags.contains(tag.label);

          return _QuickTagChip(
            label: tag.label,
            icon: tag.icon,
            isSelected: isSelected,
            onTap: () => onTagTap(tag.label),
          );
        },
      ),
    );
  }
}

class _QuickTagChip extends StatelessWidget {
  const _QuickTagChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          padding: const EdgeInsets.only(right: 5, left: 5),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  // fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTagItem {
  const _QuickTagItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
