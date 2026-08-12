import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class RentFeeDetailCard extends StatelessWidget {
  const RentFeeDetailCard({
    required this.amount,
    required this.monthlyRent,
    required this.paymentMonths,
    required this.deposit,
    required this.serviceFee,
    this.title = '费用明细',
    super.key,
  });

  final int amount;
  final int monthlyRent;
  final int paymentMonths;
  final int deposit;
  final int serviceFee;
  final String title;

  int get firstRent => monthlyRent * paymentMonths;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.md),
          _FeeRow(label: '月租金', amount: monthlyRent),
          _FeeRow(label: '首期租金（$paymentMonths个月）', amount: firstRent),
          _FeeRow(label: '押金', amount: deposit),
          _FeeRow(label: '服务费', amount: serviceFee),
          const Divider(height: 24),
          Row(
            children: [
              Text(
                '首笔应付',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const Spacer(),
              Text(
                '￥$amount',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            '￥$amount',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}
