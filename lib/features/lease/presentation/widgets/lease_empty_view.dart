import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class LeaseEmptyView extends StatelessWidget {
  const LeaseEmptyView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: AppColors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(message, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('签约后即可在这里查看租约服务', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
