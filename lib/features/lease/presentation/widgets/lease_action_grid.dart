import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class LeaseActionGrid extends StatelessWidget {
  const LeaseActionGrid({
    required this.isContractSigned,
    required this.onContractTap,
    required this.onBillTap,
    required this.onRenewTap,
    required this.onCheckoutTap,
    super.key,
  });

  final bool isContractSigned;
  final VoidCallback onContractTap;
  final VoidCallback onBillTap;
  final VoidCallback onRenewTap;
  final VoidCallback onCheckoutTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _LeaseAction(
        icon: Icons.draw_outlined,
        title: isContractSigned ? '查看合同' : '在线签约',
        subtitle: isContractSigned ? '查看电子合同' : '电子合同签约',
        onTap: onContractTap,
      ),
      _LeaseAction(
        icon: Icons.receipt_long_outlined,
        title: '账单记录',
        subtitle: '查看缴费明细',
        onTap: onBillTap,
      ),
      _LeaseAction(
        icon: Icons.event_repeat_outlined,
        title: '续租申请',
        subtitle: '提前申请续租',
        onTap: onRenewTap,
      ),
      _LeaseAction(
        icon: Icons.logout_outlined,
        title: '退租申请',
        subtitle: '提交退租申请',
        onTap: onCheckoutTap,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final action in actions)
            Expanded(child: _LeaseActionItem(action: action)),
        ],
      ),
    );
  }
}

class _LeaseActionItem extends StatelessWidget {
  const _LeaseActionItem({required this.action});

  final _LeaseAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: action.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              action.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaseAction {
  const _LeaseAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
