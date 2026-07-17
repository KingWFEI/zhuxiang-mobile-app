import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/landlord_providers.dart';

class LandlordWorkbenchPage extends ConsumerWidget {
  const LandlordWorkbenchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(landlordPendingContractCountProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('房东工作台')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(landlordPendingContractCountProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          children: [
            Text('经营管理', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _WorkbenchEntry(
              icon: Icons.home_work_outlined,
              title: '房源管理',
              subtitle: '发布、编辑和上下架房源',
              onTap: () => context.pushNamed(RouteNames.landlordHouses),
            ),
            const SizedBox(height: AppSpacing.md),
            _WorkbenchEntry(
              icon: Icons.draw_outlined,
              title: '合同签署',
              subtitle: '查看并签署待处理的租赁合同',
              badge: count != null && count > 0 ? '$count份待签' : null,
              onTap: () => context.pushNamed(RouteNames.landlordContracts),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkbenchEntry extends StatelessWidget {
  const _WorkbenchEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
