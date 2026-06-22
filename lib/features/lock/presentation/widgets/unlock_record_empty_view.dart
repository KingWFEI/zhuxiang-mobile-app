import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class UnlockRecordEmptyView extends StatelessWidget {
  const UnlockRecordEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 62,
            color: AppColors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('暂无开门记录', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('完成开锁后，记录会显示在这里', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
