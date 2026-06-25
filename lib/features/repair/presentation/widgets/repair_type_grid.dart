import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/repair_order.dart';

class RepairTypeGrid extends StatelessWidget {
  const RepairTypeGrid({
    required this.selectedType,
    required this.onSelected,
    super.key,
  });

  final RepairType? selectedType;
  final ValueChanged<RepairType> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: RepairType.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.48,
      ),
      itemBuilder: (context, index) {
        final type = RepairType.values[index];
        final isSelected = selectedType == type;
        return InkWell(
          onTap: () => onSelected(type),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(type),
                  color: isSelected ? AppColors.primary : AppColors.iconMuted,
                  size: 22,
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    type.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(RepairType type) => switch (type) {
    RepairType.plumbing => Icons.water_drop_rounded,
    RepairType.electrical => Icons.electric_bolt_rounded,
    RepairType.appliance => Icons.kitchen_rounded,
    RepairType.lock => Icons.lock_rounded,
    RepairType.furniture => Icons.chair_rounded,
    RepairType.network => Icons.wifi_rounded,
    RepairType.other => Icons.more_horiz_rounded,
  };
}
