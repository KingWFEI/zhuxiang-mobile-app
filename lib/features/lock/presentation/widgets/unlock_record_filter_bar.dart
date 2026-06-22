import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/unlock_record.dart';

class UnlockRecordFilterBar extends StatelessWidget {
  const UnlockRecordFilterBar({
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final UnlockRecordFilter selectedFilter;
  final ValueChanged<UnlockRecordFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: UnlockRecordFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = UnlockRecordFilter.values[index];
          final selected = selectedFilter == filter;
          return ChoiceChip(
            key: ValueKey('unlock-filter-${filter.name}'),
            label: Text(filter.label),
            selected: selected,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.surface : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}
