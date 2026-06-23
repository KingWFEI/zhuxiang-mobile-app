import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/rental_flow_status.dart';
import '../providers/rental_flow_providers.dart';
import '../widgets/rental_flow_stepper.dart';
import '../widgets/rental_status_card.dart';

/// 入住完成页面。
class MoveInCompletePage extends ConsumerStatefulWidget {
  const MoveInCompletePage({required this.houseId, super.key});

  final String houseId;

  @override
  ConsumerState<MoveInCompletePage> createState() => _MoveInCompletePageState();
}

class _MoveInCompletePageState extends ConsumerState<MoveInCompletePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(rentalFlowProvider);
      if (current.houseId != widget.houseId) {
        ref.read(rentalFlowProvider.notifier).loadFlow(widget.houseId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(rentalFlowProvider);
    final permission = flow.lockPermission;
    final contract = flow.contract;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('入住完成')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 72,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            flow.status == RentalFlowStatus.moveInCompleted ? '入住完成' : '流程进行中',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          RentalFlowStepper(status: flow.status),
          const SizedBox(height: AppSpacing.md),
          RentalStatusCard(state: flow),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(
            title: '租约状态',
            rows: {
              '房源ID': widget.houseId,
              '合同ID': contract?.id ?? '暂无',
              '租约状态': flow.status.label,
              '门锁ID': permission?.lockId ?? '暂无',
              '蓝牙开锁': permission?.bluetoothEnabled == true ? '已开启' : '未开启',
              '远程开锁': permission?.remoteUnlockEnabled == true ? '已开启' : '未开启',
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _EntryButton(
            icon: Icons.description_outlined,
            label: '查看我的租约',
            onTap: () => context.pushNamed(RouteNames.lease),
          ),
          _EntryButton(
            icon: Icons.lock_outline,
            label: '查看门锁详情',
            onTap: () => context.pushNamed(RouteNames.lock),
          ),
          _EntryButton(
            icon: Icons.support_agent_outlined,
            label: '联系客服',
            onTap: () => context.pushNamed(RouteNames.customerService),
          ),
          _EntryButton(
            icon: Icons.build_outlined,
            label: '提交报修',
            onTap: () => context.pushNamed(RouteNames.repairs),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(row.key, style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    child: Text(row.value, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryButton extends StatelessWidget {
  const _EntryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
