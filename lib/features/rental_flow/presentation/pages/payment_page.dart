import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/rental_flow_status.dart';
import '../providers/rental_flow_providers.dart';
import '../widgets/rental_action_bar.dart';
import '../widgets/rental_flow_stepper.dart';
import '../widgets/rental_status_card.dart';

/// 押金和首期租金支付页面。
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({required this.houseId, super.key});

  final String houseId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
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
    final payment = flow.payment;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('费用支付')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          120,
        ),
        children: [
          RentalFlowStepper(status: flow.status),
          const SizedBox(height: AppSpacing.md),
          RentalStatusCard(state: flow),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支付明细', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _AmountRow(label: '押金', amount: payment?.depositAmount ?? 0),
                _AmountRow(
                  label: '首期租金',
                  amount: payment?.firstRentAmount ?? 0,
                ),
                _AmountRow(label: '服务费', amount: payment?.serviceFee ?? 0),
                const Divider(),
                _AmountRow(
                  label: '合计',
                  amount: payment?.totalAmount ?? 0,
                  strong: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: RentalActionBar(
        primaryLabel: flow.status == RentalFlowStatus.contractSigned
            ? '创建支付订单'
            : '模拟支付并入住',
        isLoading: flow.isLoading,
        onPrimary: _handlePay,
      ),
    );
  }

  Future<void> _handlePay() async {
    final notifier = ref.read(rentalFlowProvider.notifier);
    final current = ref.read(rentalFlowProvider);
    if (current.status == RentalFlowStatus.contractSigned) {
      await notifier.createPaymentOrder();
      return;
    }
    final paid = await notifier.payOrder();
    if (!paid) return;
    final active = await notifier.activateLease();
    if (!active) return;
    final granted = await notifier.grantLockPermission();
    if (!granted) return;
    final completed = await notifier.completeMoveIn();
    if (!mounted || !completed) return;
    context.goNamed(
      RouteNames.moveInComplete,
      pathParameters: {'houseId': widget.houseId},
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.strong = false,
  });

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            '¥$amount',
            style:
                (strong ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium)
                    .copyWith(color: strong ? AppColors.primary : null),
          ),
        ],
      ),
    );
  }
}
