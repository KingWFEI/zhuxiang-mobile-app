import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/rental_flow_models.dart';
import '../../domain/rental_flow_status.dart';
import '../providers/rental_flow_providers.dart';
import '../widgets/rental_action_bar.dart';
import '../widgets/rental_flow_stepper.dart';
import '../widgets/rental_status_card.dart';

/// 合同确认与在线签约页面。
class LeaseContractPage extends ConsumerStatefulWidget {
  const LeaseContractPage({required this.houseId, super.key});

  final String houseId;

  @override
  ConsumerState<LeaseContractPage> createState() => _LeaseContractPageState();
}

class _LeaseContractPageState extends ConsumerState<LeaseContractPage> {
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
    final contract = flow.contract;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('合同签约')),
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
          if (contract == null)
            const _ContractCard(rows: {'合同状态': '暂无合同草稿'})
          else
            _ContractCard(
              rows: {
                '租客': contract.tenantName,
                '月租金': '¥${contract.rentAmount}',
                '押金': '¥${contract.depositAmount}',
                '服务费': '¥${contract.serviceFee}',
                '付款方式': contract.paymentCycle,
                '租期开始': _formatDate(contract.leaseStartDate),
                '租期结束': _formatDate(contract.leaseEndDate),
                '合同状态': contract.contractStatus.label,
              },
            ),
        ],
      ),
      bottomNavigationBar: RentalActionBar(
        primaryLabel: _primaryLabel(flow.status),
        isLoading: flow.isLoading,
        onPrimary: () => _handlePrimary(flow.status),
      ),
    );
  }

  String _primaryLabel(RentalFlowStatus status) {
    return switch (status) {
      RentalFlowStatus.leaseDraftGenerated => '确认合同',
      RentalFlowStatus.contractConfirmed => '在线签约',
      RentalFlowStatus.contractSigned => '去支付',
      _ => '继续',
    };
  }

  Future<void> _handlePrimary(RentalFlowStatus status) async {
    final notifier = ref.read(rentalFlowProvider.notifier);
    if (status == RentalFlowStatus.leaseDraftGenerated) {
      await notifier.confirmContract();
      return;
    }
    if (status == RentalFlowStatus.contractConfirmed) {
      final signed = await notifier.signContract();
      if (!mounted || !signed) return;
      context.goNamed(
        RouteNames.rentalPayment,
        pathParameters: {'houseId': widget.houseId},
      );
      return;
    }
    if (status == RentalFlowStatus.contractSigned && mounted) {
      context.goNamed(
        RouteNames.rentalPayment,
        pathParameters: {'houseId': widget.houseId},
      );
    }
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.rows});

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
          Text('租约草稿', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
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

extension on ContractStatus {
  String get label {
    return switch (this) {
      ContractStatus.draft => '待确认',
      ContractStatus.confirmed => '已确认',
      ContractStatus.signed => '已签约',
    };
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
