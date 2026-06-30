import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/payment_providers.dart';
import '../../domain/entities/payment_record.dart';

class PaymentDetailPage extends ConsumerWidget {
  const PaymentDetailPage({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(paymentDetailProvider(paymentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _PageHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    108,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: detail.when(
                      loading: () => const SizedBox(
                        height: 360,
                        child: AppLoadingView(message: '正在加载支付详情'),
                      ),
                      error: (error, _) => SizedBox(
                        height: 360,
                        child: AppErrorView(
                          message: '支付详情加载失败',
                          onRetry: () =>
                              ref.invalidate(paymentDetailProvider(paymentId)),
                        ),
                      ),
                      data: (record) => _PaymentDetailCard(record: record),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: AppSpacing.sm,
            child: IconButton(
              onPressed: () => context.canPop() ? context.pop() : null,
              icon: AppIcon.iconBack,
            ),
          ),
          Text('支付详情', style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}

class _PaymentDetailCard extends StatelessWidget {
  const _PaymentDetailCard({required this.record});

  final PaymentRecord record;

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
          Center(
            child: Column(
              children: [
                Text(
                  _formatMoney(record.amount),
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 32),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  record.statusText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _statusColor(record.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _InfoRow(label: '支付类型', value: record.typeText),
          _InfoRow(label: '房源', value: record.houseName),
          _InfoRow(label: '支付方式', value: record.channelText),
          _InfoRow(label: '支付编号', value: record.paymentNo),
          _InfoRow(label: '渠道流水', value: record.channelTradeNo),
          _InfoRow(label: '订单ID', value: record.orderId ?? '--'),
          _InfoRow(label: '租约ID', value: record.leaseId ?? '--'),
          _InfoRow(label: '账单ID', value: record.billId ?? '--'),
          _InfoRow(label: '创建时间', value: _formatDateTime(record.createdAt)),
          _InfoRow(
            label: '支付时间',
            value: record.paidAt == null
                ? '--'
                : _formatDateTime(record.paidAt!),
          ),
          if (record.remark.isNotEmpty)
            _InfoRow(label: '备注', value: record.remark),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value.isEmpty ? '--' : value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(PaymentRecordStatus status) {
  return switch (status) {
    PaymentRecordStatus.pending => AppColors.warning,
    PaymentRecordStatus.success => AppColors.secondary,
    PaymentRecordStatus.failed => AppColors.error,
    PaymentRecordStatus.refunded => AppColors.primary,
  };
}

String _formatMoney(int amount) {
  final prefix = amount < 0 ? '-¥' : '¥';
  final value = amount.abs() / 100;
  return '$prefix${value.toStringAsFixed(amount.abs() % 100 == 0 ? 0 : 2)}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
