import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/rent_order.dart';

class RentOrderHouseCard extends StatelessWidget {
  const RentOrderHouseCard({required this.order, super.key});

  final RentOrder order;

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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: order.coverUrl.isEmpty
                ? Container(
                    width: 82,
                    height: 82,
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.apartment,
                      color: AppColors.primary,
                    ),
                  )
                : Image.network(
                    order.coverUrl,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.houseName,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(order.address, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  order.roomName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
