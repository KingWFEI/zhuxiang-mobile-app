import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/payment_providers.dart';
import '../../domain/entities/payment_record.dart';

class PaymentRecordsPage extends ConsumerStatefulWidget {
  const PaymentRecordsPage({super.key});

  @override
  ConsumerState<PaymentRecordsPage> createState() => _PaymentRecordsPageState();
}

class _PaymentRecordsPageState extends ConsumerState<PaymentRecordsPage> {
  String? _status;
  String? _type;

  @override
  Widget build(BuildContext context) {
    final query = PaymentRecordQuery(status: _status, type: _type);
    final result = ref.watch(paymentRecordsProvider(query));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(paymentRecordsProvider(query)),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PaymentFilters(
                            status: _status,
                            type: _type,
                            onStatusChanged: (value) =>
                                setState(() => _status = value),
                            onTypeChanged: (value) =>
                                setState(() => _type = value),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          result.when(
                            loading: () => const SizedBox(
                              height: 360,
                              child: AppLoadingView(message: '正在加载支付记录'),
                            ),
                            error: (error, _) => SizedBox(
                              height: 360,
                              child: AppErrorView(
                                message: '支付记录加载失败，请稍后重试',
                                onRetry: () => ref.invalidate(
                                  paymentRecordsProvider(query),
                                ),
                              ),
                            ),
                            data: (page) => _PaymentList(records: page.items),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed(RouteNames.profile);
              },
              icon: AppIcon.iconBack,
            ),
          ),
          Text('支付记录', style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}

class _PaymentFilters extends StatelessWidget {
  const _PaymentFilters({
    required this.status,
    required this.type,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  final String? status;
  final String? type;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: status == null,
                onSelected: () => onStatusChanged(null),
              ),
              for (final item in PaymentRecordStatus.values)
                _FilterChip(
                  label: item.label,
                  selected: status == item.name,
                  onSelected: () => onStatusChanged(item.name),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部类型',
                selected: type == null,
                onSelected: () => onTypeChanged(null),
              ),
              for (final item in PaymentRecordType.values)
                _FilterChip(
                  label: item.label,
                  selected: type == item.value,
                  onSelected: () => onTypeChanged(item.value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({required this.records});

  final List<PaymentRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(
        height: 320,
        child: AppEmptyView(message: '暂无支付记录'),
      );
    }

    return Column(
      children: [
        for (final record in records) ...[
          _PaymentRecordCard(record: record),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _PaymentRecordCard extends StatelessWidget {
  const _PaymentRecordCard({required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => context.pushNamed(
        RouteNames.paymentDetail,
        pathParameters: {'paymentId': record.id},
      ),
      child: Container(
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(record.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _typeIcon(record.type),
                    color: _statusColor(record.status),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.typeText,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        record.houseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatMoney(record.amount),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: record.type == PaymentRecordType.refund
                        ? AppColors.secondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatusChip(status: record.status),
                const Spacer(),
                Text(
                  _formatDateTime(record.paidAt ?? record.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentRecordStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _typeIcon(PaymentRecordType type) {
  return switch (type) {
    PaymentRecordType.rent => Icons.home_work,
    PaymentRecordType.deposit => Icons.account_balance_wallet,
    PaymentRecordType.serviceFee => Icons.receipt_long,
    PaymentRecordType.refund => Icons.replay,
  };
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
