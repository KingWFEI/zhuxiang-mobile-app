import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/contract_preview.dart';
import '../../domain/entities/rent_order.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/agreement_checkbox.dart';
import '../widgets/rent_order_house_card.dart';
import '../widgets/rental_flow_bottom_bar.dart';
import '../widgets/rental_flow_page_shell.dart';
import '../widgets/rent_order_deadline_banner.dart';

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
        if (order?.prePaymentDeadline != null) ...[
          const SizedBox(height: AppSpacing.md),
          RentOrderDeadlineBanner(
            order: order!,
            onExpired: _handleDeadlineExpired,
          ),
        ],
        if (order != null) const SizedBox(height: AppSpacing.lg),
        if (contract != null)
          FlowCard(
            child: Column(
              children: [
                InfoRow(label: '甲方姓名', value: contract.landlordName),
                if (contract.landlordPhone.isNotEmpty)
                  InfoRow(label: '甲方手机号', value: contract.landlordPhone),
                if (contract.landlordIdCard.isNotEmpty)
                  InfoRow(label: '甲方身份证', value: contract.landlordIdCard),
                InfoRow(label: '乙方姓名', value: contract.tenantName),
              ],
            ),
          ),
        if (contract != null) const SizedBox(height: AppSpacing.lg),
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
    final source = contract;
    final tenantName = source?.tenantName.isNotEmpty == true
        ? source!.tenantName
        : '乙方';
    final landlordName = source?.landlordName.isNotEmpty == true
        ? source!.landlordName
        : '甲方';
    final houseName = source?.houseName.isNotEmpty == true
        ? source!.houseName
        : (order?.houseName ?? '出租房屋');
    // 合同预览接口目前没有单独的 address 字段，优先使用订单中的房屋地址。
    final address = order?.address.trim().isNotEmpty == true
        ? order!.address.trim()
        : houseName;
    final startDate = source?.startDate ?? order?.startDate;
    final endDate = source?.endDate ?? order?.endDate;
    final leaseMonths =
        order?.leaseMonths ?? _monthsBetween(startDate, endDate);
    final monthlyRent = source?.monthlyRent ?? order?.monthlyRent ?? 0;
    final deposit = source?.deposit ?? order?.deposit ?? 0;
    final paymentMethod = source?.paymentMethod.isNotEmpty == true
        ? source!.paymentMethod
        : (order?.paymentMethod ?? '线上支付');

    if (startDate == null || endDate == null) {
      return '正在生成合同条款，请稍后重试。';
    }

    return [
      '根据《中华人民共和国合同法》及相关法律法规的规定，$landlordName（甲方）与$tenantName（乙方）在平等自愿基础上，就甲方将房屋出租给乙方使用、乙方承租甲方房屋事宜，为明确双方权利义务，经协商一致，订立本合同。',
      '一、房屋坐落：$houseName，$address。',
      '二、房屋租期为${_formatLeaseTerm(leaseMonths)}（实际租期$leaseMonths个月），从${_formatContractDate(startDate)}至${_formatContractDate(endDate)}。乙方租赁房屋作为居住使用。租赁期满，甲方有权收回出租的房屋，乙方应如期归还。乙方要求续租，则必须在租赁期满日一个月前通知甲方，经甲方同意后，乙方在交清全年租金的同时，重新签订租赁合同。如果乙方不再租房，须提前一个月告知甲方。',
      '三、为保证本合同的执行，乙方须向甲方一次交付押金${_formatContractMoney(deposit)}元整。',
      '四、本合同的租金支付方式为线上支付（$paymentMethod），先付后用。乙方须一次向甲方交足租金${_formatContractMoney(monthlyRent)}元整，租金交付日为${_formatContractDate(startDate)}前。',
      '五、在租用期间所发生的水费、电费、物业费、取暖费、天然气费、有线电视收视费等费用，由乙方自行负担。',
      '六、甲乙双方的权利和责任：\n1. 甲乙双方在合同存续期间均无权单方终止履行合同，如有异议应由双方协商解决。协商不成时，不影响本合同的执行（本条第四款情况除外）。\n2. 乙方在居住期间应维护好房屋结构、设备、物品和门窗的完整。如有损坏，需在合同期满日之前恢复原貌，由此所发生的费用由乙方负担；设备、物品如有损坏，须照价赔偿。\n3. 乙方在租房期间，应保持屋内整洁，不得使用煤作燃料；应注意各方面的安全，如有不安全隐患或由此引发任何后果均由乙方一方承担。\n4. 乙方在租住期间不得把此房屋转借、转租给他人使用，不得改变租赁用途或利用此房屋进行违法犯罪等性质的活动，不得改变房屋结构和损坏房屋。如有上述情况发生，甲方有权单方终止合同的执行，由此给甲方造成的损失由乙方承担赔偿。\n5. 租赁的房屋如因不可抗拒的原因导致损毁或因市政建设需要拆除和改建造成损失的，甲乙双方互不承担责任。因此而终止合同时，租金按实际使用时间计算。\n6. 双方电话号码变更应及时通知对方。',
      '七、本合同未尽事宜，由双方协商解决。',
      '八、本协议书一式二份，双方各执一份。',
    ].join('\n\n');
  }

  String _formatContractDate(DateTime value) {
    return '${value.year}年${value.month}月${value.day}日';
  }

  String _formatContractMoney(int amount) {
    return amount.toString();
  }

  String _formatLeaseTerm(int months) {
    if (months > 0 && months % 12 == 0) return '${months ~/ 12}年';
    return '$months个月';
  }

  int _monthsBetween(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    final monthDelta = (end.year - start.year) * 12 + end.month - start.month;
    final months = monthDelta + (end.day >= start.day ? 1 : 0);
    return months > 0 ? months : 1;
  }

  void _load() {
    ref
        .read(rentalFlowControllerProvider.notifier)
        .loadContractPreview(widget.orderId);
  }

  void _handleDeadlineExpired() {
    ref.invalidate(myRentOrdersProvider);
    if (!mounted) return;
    AppToast.show(context, '订单办理超时，房源已释放');
    context.goNamed(RouteNames.rentOrders);
  }

  Future<void> _submit() async {
    if (!_agreed) {
      AppToast.show(context, '请先确认合同内容', type: AppToastType.error);
      return;
    }
    final ok = await ref
        .read(rentalFlowControllerProvider.notifier)
        .confirmContract(widget.orderId);
    if (!mounted || !ok) return;
    context.pushReplacementNamed(
      RouteNames.onlineSign,
      pathParameters: {'orderId': widget.orderId},
    );
  }
}
