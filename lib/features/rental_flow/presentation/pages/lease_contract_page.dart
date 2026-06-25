import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/agreement_checkbox.dart';
import '../widgets/rent_order_house_card.dart';
import '../widgets/rental_flow_bottom_bar.dart';
import '../widgets/rental_flow_page_shell.dart';

class LeaseContractPage extends ConsumerStatefulWidget {
  const LeaseContractPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<LeaseContractPage> createState() => _LeaseContractPageState();
}

class _LeaseContractPageState extends ConsumerState<LeaseContractPage> {
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    final order = state.order;
    final contract = state.contractPreview;
    return RentalFlowPageShell(
      title: '合同预览',
      step: RentalFlowStep.contract,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: _load,
      bottomNavigationBar: RentalFlowBottomBar(
        primaryLabel: '确认合同',
        isLoading: state.isSubmitting,
        onPrimary: _submit,
      ),
      children: [
        if (order != null) RentOrderHouseCard(order: order),
        if (order != null) const SizedBox(height: AppSpacing.lg),
        if (order != null)
          FlowCard(
            child: Column(
              children: [
                InfoRow(label: '起租日期', value: formatDate(order.startDate)),
                InfoRow(label: '租期', value: '${order.leaseMonths}个月'),
                InfoRow(label: '月租金', value: '￥${order.monthlyRent}'),
                InfoRow(label: '押金', value: '￥${order.deposit}'),
                InfoRow(label: '付款方式', value: order.paymentMethod),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '合同正文预览',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                contract?.clauses.map((item) => '· $item').join('\n\n') ??
                    '正在生成合同条款，请稍后重试。',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AgreementCheckbox(
          value: _agreed,
          text: '我已阅读并确认合同内容',
          onChanged: (value) => setState(() => _agreed = value),
        ),
      ],
    );
  }

  void _load() {
    ref
        .read(rentalFlowControllerProvider.notifier)
        .loadContractPreview(widget.orderId);
  }

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先确认合同内容')));
      return;
    }
    final ok = await ref
        .read(rentalFlowControllerProvider.notifier)
        .confirmContract(widget.orderId);
    if (!mounted || !ok) return;
    context.pushReplacementNamed(
      RouteNames.rentalPayment,
      pathParameters: {'orderId': widget.orderId},
    );
  }
}
