import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/rental_flow_step.dart';

class RentalStepIndicator extends StatelessWidget {
  const RentalStepIndicator({required this.currentStep, super.key});

  final RentalFlowStep currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = RentalFlowStep.values;
    final currentIndex = steps.indexOf(currentStep);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _StepItem(
                label: steps[index].label,
                isActive: index == currentIndex,
                isDone: index < currentIndex,
              ),
            ),
            if (index != steps.length - 1)
              Container(
                width: 14,
                height: 2,
                color: index < currentIndex
                    ? AppColors.primary
                    : AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isActive || isDone ? AppColors.primary : AppColors.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive || isDone
                ? AppColors.primary
                : AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            size: isDone ? 14 : 8,
            color: isActive || isDone ? Colors.white : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
