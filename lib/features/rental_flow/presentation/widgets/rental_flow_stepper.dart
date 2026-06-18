import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/rental_flow_status.dart';

/// 租房流程进度条。
class RentalFlowStepper extends StatelessWidget {
  const RentalFlowStepper({required this.status, super.key});

  final RentalFlowStatus status;

  static const _steps = [
    _FlowStep('预约看房', RentalFlowStatus.appointmentPending),
    _FlowStep('提交申请', RentalFlowStatus.applicationSubmitted),
    _FlowStep('实名认证', RentalFlowStatus.realNameVerified),
    _FlowStep('签署合同', RentalFlowStatus.contractSigned),
    _FlowStep('支付费用', RentalFlowStatus.paid),
    _FlowStep('门锁授权', RentalFlowStatus.lockPermissionGranted),
    _FlowStep('入住完成', RentalFlowStatus.moveInCompleted),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < _steps.length; index++) ...[
                Expanded(
                  child: _StepDot(step: _steps[index], status: status),
                ),
                if (index != _steps.length - 1)
                  Container(
                    width: 16,
                    height: 2,
                    color: status.isAtLeast(_steps[index + 1].status)
                        ? AppColors.primary
                        : AppColors.border,
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _steps
                .map(
                  (step) => Expanded(
                    child: Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: status.isAtLeast(step.status)
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: status.isAtLeast(step.status)
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step, required this.status});

  final _FlowStep step;
  final RentalFlowStatus status;

  @override
  Widget build(BuildContext context) {
    final done = status.isAtLeast(step.status);
    return Center(
      child: CircleAvatar(
        radius: 10,
        backgroundColor: done ? AppColors.primary : AppColors.border,
        child: Icon(
          done ? Icons.check_rounded : Icons.circle,
          size: done ? 14 : 8,
          color: done ? AppColors.surface : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _FlowStep {
  const _FlowStep(this.label, this.status);

  final String label;
  final RentalFlowStatus status;
}
