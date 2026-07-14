import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/deposit.dart';

class DepositDetailPage extends ConsumerWidget {
  const DepositDetailPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(depositDetailProvider(leaseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('押金详情'),
        leading: IconButton(
          icon: AppIcon.iconBack,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: result.when(
        loading: () => const AppLoadingView(message: '正在加载押金信息'),
        error: (error, _) => AppErrorView(
          message: '押金信息加载失败',
          onRetry: () => ref.invalidate(depositDetailProvider(leaseId)),
        ),
        data: (deposit) {
          if (deposit == null) {
            return const AppEmptyView(message: '暂无押金记录');
          }
          return _DepositContent(deposit: deposit);
        },
      ),
    );
  }
}

class _DepositContent extends StatelessWidget {
  const _DepositContent({required this.deposit});

  final DepositInfo deposit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
            AppSpacing.pageHorizontal,
            48,
          ),
          children: [
            _AmountSummary(deposit: deposit),
            const SizedBox(height: AppSpacing.xl),
            _StatusFlow(deposit: deposit),
            if (deposit.deductions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle(title: '扣款明细'),
              const SizedBox(height: AppSpacing.md),
              ...deposit.deductions.map((d) => _DeductionTile(deduction: d)),
            ],
            if (deposit.status == 'refunding' && deposit.pendingAmount > 0) ...[
              const SizedBox(height: AppSpacing.xl),
              _RefundHint(amount: deposit.pendingAmount),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({required this.deposit});

  final DepositInfo deposit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _AmountBlock(
              label: '押金总额',
              value: '¥${_formatMoney(deposit.amount)}',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(width: 1, height: 48, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _AmountBlock(
              label: '已扣款',
              value: '¥${_formatMoney(deposit.withheldAmount)}',
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(width: 1, height: 48, color: AppColors.border),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _AmountBlock(
              label: '应退金额',
              value: '¥${_formatMoney(deposit.pendingAmount)}',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusFlow extends StatelessWidget {
  const _StatusFlow({required this.deposit});

  final DepositInfo deposit;

  static const _steps = [
    ('托管中', Icons.shield_outlined),
    ('已扣款', Icons.remove_circle_outline),
    ('退款中', Icons.sync_rounded),
    ('已退款', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final current = deposit.statusIndex;

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
          Text('押金状态', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= current ? AppColors.primary : AppColors.border,
                    ),
                  ),
                _StepDot(
                  label: _steps[i].$1,
                  icon: _steps[i].$2,
                  active: i <= current,
                  current: i == current,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.icon,
    required this.active,
    required this.current,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.border;
    final bgColor =
        active ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background;
    final textColor = active ? AppColors.primary : AppColors.textMuted;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: current ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleMedium);
  }
}

class _DeductionTile extends StatelessWidget {
  const _DeductionTile({required this.deduction});

  final DepositDeduction deduction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.remove_rounded, color: AppColors.error),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      deduction.typeLabel,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '-¥${_formatMoney(deduction.amount)}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (deduction.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    deduction.description,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundHint extends StatelessWidget {
  const _RefundHint({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Text(
            '预计退款 ¥${_formatMoney(amount)}',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(int amount) {
  final yuan = amount / 100;
  return yuan == yuan.roundToDouble()
      ? yuan.toInt().toString()
      : yuan.toStringAsFixed(2);
}
