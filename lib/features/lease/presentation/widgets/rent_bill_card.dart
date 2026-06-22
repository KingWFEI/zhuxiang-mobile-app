import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'current_lease_card.dart';

class RentBillCard extends StatelessWidget {
  const RentBillCard({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.onPayTap,
    super.key,
  });

  final String title;
  final int amount;
  final DateTime dueDate;
  final VoidCallback onPayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('应付金额', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '￥${formatLeaseMoney(amount)}',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '请于${dueDate.month.toString().padLeft(2, '0')}月${dueDate.day.toString().padLeft(2, '0')}日前完成支付，逾期将产生滞纳金',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPayTap,
              child: const Text('去缴租'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.success,
                size: 17,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '租金通过官方渠道安全支付，资金守护，交易无忧',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
