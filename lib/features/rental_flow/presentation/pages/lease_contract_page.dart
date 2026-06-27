import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/contract_preview.dart';
import '../../domain/entities/rent_order.dart';
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
    final contractText = _contractText(order, contract);
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
                contractText,
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

  String _contractText(RentOrder? order, ContractPreview? contract) {
    final content = contract?.content.trim() ?? '';
    if (content.isNotEmpty) return content;

    final clauses = contract?.clauses ?? const <String>[];
    final visibleClauses = clauses
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (visibleClauses.isNotEmpty) {
      return visibleClauses.map((item) => '· $item').join('\n\n');
    }

    if (order == null) return '正在生成合同条款，请稍后重试。';
    return [
      '· 甲乙双方确认房源信息：${order.houseName}，地址为${order.address}。',
      '· 租赁期限：自${formatDate(order.startDate)}起至${formatDate(order.endDate)}止，共计${order.leaseMonths}个月。',
      '· 租金及支付方式：月租金为人民币${order.monthlyRent}元，押金为人民币${order.deposit}元，付款方式为${order.paymentMethod}。',
      '· 房屋用途：乙方承诺该房屋仅作为居住使用，不得擅自改变用途或转租。',
      '· 维修责任：房屋及其设施设备的自然损耗由出租方负责维修，承租方人为损坏由承租方承担。',
      '· 合同解除：任何一方提前解除合同，应提前通知对方并按合同约定处理费用。',
    ].join('\n\n');
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
