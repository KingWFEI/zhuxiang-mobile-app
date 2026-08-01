import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/models/bill_model.dart';
import '../../data/providers/bill_providers.dart';
import '../../data/services/bill_service.dart';
import '../../domain/entities/bill.dart';
import 'bill_payment_page.dart';

class BillListPage extends ConsumerStatefulWidget {
  const BillListPage({super.key});

  @override
  ConsumerState<BillListPage> createState() => _BillListPageState();
}

class _BillListPageState extends ConsumerState<BillListPage> {
  var _activeTab = 0; // 0=未到期 1=待支付 2=已支付

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(myBillsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _BillHeader(
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.goNamed(RouteNames.profile);
                  },
                ),
                Expanded(
                  child: result.when(
                    loading: () =>
                        const AppLoadingView(message: '正在加载账单'),
                    error: (error, _) => AppErrorView(
                      message: '账单加载失败',
                      onRetry: () => ref.invalidate(myBillsProvider),
                    ),
                    data: (data) => RefreshIndicator(
                      onRefresh: () async => ref.invalidate(myBillsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal,
                          AppSpacing.lg,
                          AppSpacing.pageHorizontal,
                          108,
                        ),
                        children: [
                          _BillSegment(
                            tabs: [
                              _TabInfo('未到期', data.scheduledBills.length),
                              _TabInfo('待支付', data.pendingBills.length),
                              _TabInfo('已支付', data.paidBills.length),
                            ],
                            activeIndex: _activeTab,
                            onChanged: (i) => setState(() => _activeTab = i),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          switch (_activeTab) {
                            0 => _buildScheduledBills(context, data),
                            1 => _buildPendingBills(context, data),
                            _ => _buildPaidBills(context, data),
                          },
                        ],
                      ),
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

  Widget _buildScheduledBills(BuildContext context, BillGroupedResponse data) {
    if (data.scheduledBills.isEmpty) {
      return const AppEmptyView(message: '暂无未到期账单');
    }
    return Column(
      children: data.scheduledBills.map((bill) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _BillCard(bill: bill),
        );
      }).toList(),
    );
  }

  Widget _buildPendingBills(BuildContext context, BillGroupedResponse data) {
    if (data.pendingBills.isEmpty) {
      return const AppEmptyView(message: '暂无待付账单');
    }
    return Column(
      children: data.pendingBills.map((bill) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _BillCard(
            bill: bill,
            onPay: () => _payBill(context, bill),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaidBills(BuildContext context, BillGroupedResponse data) {
    if (data.paidBills.isEmpty) {
      return const AppEmptyView(message: '暂无已付账单');
    }
    return Column(
      children: data.paidBills.map((bill) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _BillCard(bill: bill),
        );
      }).toList(),
    );
  }

  void _payBill(BuildContext context, BillModel bill) async {
    final result = await ref
        .read(billServiceProvider)
        .payBill(bill.id, 'mock');

    if (result.needWebView) {
      if (!context.mounted) return;
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BillPaymentPage(
            paymentUrl: result.paymentUrl!,
            billId: bill.id,
            paymentNo: result.paymentNo,
          ),
        ),
      );
      if (paid == true && context.mounted) {
        ref.invalidate(myBillsProvider);
      }
      return;
    }

    // mock 支付完成
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付成功')),
      );
      ref.invalidate(myBillsProvider);
    }
  }
}

class _TabInfo {
  const _TabInfo(this.label, this.count);
  final String label;
  final int count;
}

class _BillSegment extends StatelessWidget {
  const _BillSegment({
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<_TabInfo> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          return Expanded(
            child: _SegTab(
              label: '${tabs[i].label} (${tabs[i].count})',
              selected: activeIndex == i,
              onTap: () => onChanged(i),
            ),
          );
        }),
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill, this.onPay});

  final BillModel bill;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final isActive = bill.canPay;
    final isScheduled = bill.status == BillStatus.scheduled;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: bill.houseImageUrl.isNotEmpty
                      ? Image.network(
                          bill.houseImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(
                              Icons.receipt_long,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(
                            Icons.receipt_long,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.houseName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '第${bill.periodNo}期 · 应缴日 ${_formatDate(bill.dueDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '￥${_yuan(bill.amountDue)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : isScheduled
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                    ),
                  ),
                  if (bill.overdueAmount > 0)
                    Text(
                      '+滞纳金 ￥${_yuan(bill.overdueAmount)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  _StatusLabel(status: bill.status),
                ],
              ),
            ],
          ),
          if (isActive && onPay != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPay,
                child: Text(
                  bill.isOverdue ? '立即补缴' : '立即支付',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  static String _yuan(int fen) {
    final yuan = fen / 100.0;
    return yuan == yuan.toInt() ? yuan.toInt().toString() : yuan.toStringAsFixed(2);
  }
}

class _BillHeader extends StatelessWidget {
  const _BillHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppIcon.iconBack,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '我的账单',
                  style: AppTextStyles.normalPageTitle,
                ),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final BillStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case BillStatus.paid:
        color = AppColors.success;
        text = '已支付';
      case BillStatus.overdue:
        color = AppColors.error;
        text = '已逾期';
      case BillStatus.cancelled:
        color = AppColors.textMuted;
        text = '已取消';
      case BillStatus.pending:
        color = AppColors.warning;
        text = '待支付';
      case BillStatus.scheduled:
        color = AppColors.textSecondary;
        text = '未到期';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
