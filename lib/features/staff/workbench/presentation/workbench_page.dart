import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class WorkbenchPage extends ConsumerWidget {
  const WorkbenchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('工作台')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _InfoCard(),
            const SizedBox(height: AppSpacing.lg),
            _QuickActions(),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => _confirmLogout(context, ref),
              child: const Text('退出登录'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.goNamed(RouteNames.login);
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.work_outline, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('员工工作台', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('管理房源门锁、配置智能门锁', style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '可在此统一管理待办任务、门锁状态和现场操作。',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '快捷操作',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.lock_outline,
                label: '初始化门锁',
                onTap: () => context.goNamed(RouteNames.staffLockInit),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
