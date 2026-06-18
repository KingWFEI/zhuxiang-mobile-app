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

/// 看房预约详情页面。
class ViewingDetailPage extends ConsumerStatefulWidget {
  const ViewingDetailPage({required this.houseId, super.key});

  final String houseId;

  @override
  ConsumerState<ViewingDetailPage> createState() => _ViewingDetailPageState();
}

class _ViewingDetailPageState extends ConsumerState<ViewingDetailPage> {
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
    final appointment = flow.appointment;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('预约详情')),
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
          if (appointment == null)
            const _InfoCard(title: '预约信息', rows: {'状态': '暂无预约记录'})
          else
            _InfoCard(
              title: appointment.houseTitle,
              rows: {
                '预约状态': appointment.status.label,
                '看房方式': appointment.viewingType == ViewingType.offline
                    ? '线下看房'
                    : '视频看房',
                '预约日期': _formatDate(appointment.appointmentDate),
                '时间段': appointment.appointmentTimeRange,
                '联系人': appointment.contactName,
                '手机号': appointment.contactPhone,
                if (appointment.remark.isNotEmpty) '备注': appointment.remark,
              },
            ),
        ],
      ),
      bottomNavigationBar: RentalActionBar(
        primaryLabel: _primaryLabel(flow.status),
        secondaryLabel: flow.status == RentalFlowStatus.appointmentConfirmed
            ? '标记已看房'
            : null,
        isLoading: flow.isLoading,
        onSecondary: _completeViewing,
        onPrimary: () => _handlePrimary(flow.status),
      ),
    );
  }

  String _primaryLabel(RentalFlowStatus status) {
    return switch (status) {
      RentalFlowStatus.appointmentPending => '模拟房东确认',
      RentalFlowStatus.appointmentConfirmed => '我想租这套',
      RentalFlowStatus.viewingCompleted => '确认租房意向',
      RentalFlowStatus.intentionConfirmed => '填写租房申请',
      _ => '下一步',
    };
  }

  Future<void> _handlePrimary(RentalFlowStatus status) async {
    final notifier = ref.read(rentalFlowProvider.notifier);
    if (status == RentalFlowStatus.appointmentPending) {
      await notifier.simulateLandlordConfirm();
      return;
    }
    if (status == RentalFlowStatus.appointmentConfirmed) {
      final completed = await notifier.completeViewing();
      if (!completed) return;
      await notifier.confirmIntention();
    } else if (status == RentalFlowStatus.viewingCompleted) {
      await notifier.confirmIntention();
    }
    if (!mounted) return;
    final current = ref.read(rentalFlowProvider);
    if (current.status.isAtLeast(RentalFlowStatus.intentionConfirmed)) {
      context.goNamed(
        RouteNames.rentalApplication,
        pathParameters: {'houseId': widget.houseId},
      );
    }
  }

  Future<void> _completeViewing() async {
    await ref.read(rentalFlowProvider.notifier).completeViewing();
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

extension on AppointmentStatus {
  String get label {
    return switch (this) {
      AppointmentStatus.pending => '待确认',
      AppointmentStatus.confirmed => '已确认',
      AppointmentStatus.completed => '已看房',
      AppointmentStatus.cancelled => '已取消',
    };
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
