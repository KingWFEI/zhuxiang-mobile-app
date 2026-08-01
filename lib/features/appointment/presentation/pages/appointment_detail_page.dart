import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/appointment_models.dart';
import '../../data/providers/appointment_providers.dart';
import 'appointment_list_page.dart';

class AppointmentDetailPage extends ConsumerWidget {
  const AppointmentDetailPage({
    required this.appointmentId,
    this.returnHouseId,
    super.key,
  });

  final String appointmentId;
  final String? returnHouseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(appointmentDetailProvider(appointmentId));
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('预约详情'),
          centerTitle: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: FilledButton.tonal(
              onPressed: () =>
                  ref.invalidate(appointmentDetailProvider(appointmentId)),
              child: const Text('加载失败，点击重试'),
            ),
          ),
          data: (value) => _DetailBody(
            detail: value,
            onAction: (action) => _handleAction(context, ref, value, action),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final houseId = returnHouseId?.trim() ?? '';
    if (houseId.isNotEmpty) {
      context.goNamed(
        RouteNames.houseDetail,
        pathParameters: {'houseId': houseId},
      );
      return;
    }
    context.goNamed(RouteNames.home);
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    AppointmentDetail detail,
    String action,
  ) async {
    try {
      switch (action) {
        case 'CANCEL':
          final confirmed = await _confirm(
            context,
            title: '取消预约',
            content: '确定取消本次看房预约吗？',
          );
          if (!confirmed) return;
          await ref
              .read(appointmentServiceProvider)
              .cancel(detail.id, '租客主动取消');
          break;
        case 'ACCEPT_RESCHEDULE':
          await ref
              .read(appointmentServiceProvider)
              .acceptReschedule(detail.id);
          break;
        case 'REJECT_RESCHEDULE':
          await ref
              .read(appointmentServiceProvider)
              .rejectReschedule(detail.id, '无法接受新的预约时间');
          break;
        case 'UNLOCK':
        case 'VIEW_PASSCODE':
          if (context.mounted) {
            await context.pushNamed(
              RouteNames.appointmentUnlock,
              pathParameters: {'appointmentId': detail.id},
            );
          }
          return;
        case 'CONTACT_HOST':
          final phone = detail.host?.phoneMasked ?? '';
          if (phone.contains('*') || phone.isEmpty) {
            throw StateError('房东暂未开放联系电话');
          }
          await launchUrl(Uri(scheme: 'tel', path: phone));
          return;
        case 'NAVIGATE':
          final query = Uri.encodeComponent(
            detail.meetingPoint.isNotEmpty
                ? detail.meetingPoint
                : detail.house.address,
          );
          await launchUrl(
            Uri.parse('https://uri.amap.com/search?keyword=$query'),
            mode: LaunchMode.externalApplication,
          );
          return;
      }
      ref.invalidate(appointmentDetailProvider(detail.id));
      ref.invalidate(myAppointmentsProvider);
      if (context.mounted) {
        AppToast.show(context, '操作成功', type: AppToastType.success);
      }
    } on Object catch (error) {
      if (context.mounted) {
        AppToast.show(context, '$error', type: AppToastType.error);
      }
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.onAction});

  final AppointmentDetail detail;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.house.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(detail.sourceLabel)),
                  Chip(label: Text(detail.viewingModeLabel)),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: '状态',
                value: appointmentStatusLabel(detail.status),
                valueColor: appointmentStatusColor(detail.status),
              ),
              _InfoRow(
                label: '时间',
                value: _formatDateRange(
                  detail.appointmentStartAt,
                  detail.appointmentEndAt,
                ),
              ),
              _InfoRow(label: '地址', value: detail.house.address),
              _InfoRow(
                label: '联系人',
                value: '${detail.contactName} ${detail.contactPhone}',
              ),
              if (detail.remark.isNotEmpty)
                _InfoRow(label: '备注', value: detail.remark),
            ],
          ),
        ),
        if (detail.status == 'RESCHEDULE_PROPOSED') ...[
          const SizedBox(height: 12),
          _Card(
            color: const Color(0xFFFFFBEB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '接待方建议调整时间',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateRange(
                    detail.proposedStartAt,
                    detail.proposedEndAt,
                  ),
                ),
                if (detail.rescheduleReason.isNotEmpty)
                  Text(detail.rescheduleReason),
              ],
            ),
          ),
        ],
        if (detail.viewingMode != 'SELF_SERVICE_LOCK' &&
            (detail.meetingPoint.isNotEmpty ||
                detail.viewingInstruction.isNotEmpty ||
                detail.host != null)) ...[
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '接待信息',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (detail.host != null)
                  _InfoRow(
                    label: detail.viewingMode == 'LANDLORD_HOSTED'
                        ? '房东'
                        : '平台管家',
                    value: '${detail.host!.name} ${detail.host!.phoneMasked}',
                  ),
                if (detail.meetingPoint.isNotEmpty)
                  _InfoRow(label: '见面地点', value: detail.meetingPoint),
                if (detail.viewingInstruction.isNotEmpty)
                  _InfoRow(label: '看房说明', value: detail.viewingInstruction),
                if (detail.checkinCode.isNotEmpty)
                  _InfoRow(label: '预约核验码', value: detail.checkinCode),
              ],
            ),
          ),
        ],
        if (detail.viewingMode == 'SELF_SERVICE_LOCK') ...[
          const SizedBox(height: 12),
          _Card(
            child: _InfoRow(
              label: '开门凭证',
              value: _accessLabel(detail.accessStatus),
              valueColor: detail.accessStatus == 'ACTIVE'
                  ? const Color(0xFF0E9F6E)
                  : const Color(0xFFD97706),
            ),
          ),
        ],
        if (detail.rejectReason.isNotEmpty ||
            detail.cancelReason.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Card(
            color: const Color(0xFFFEF2F2),
            child: Text(
              detail.rejectReason.isNotEmpty
                  ? detail.rejectReason
                  : detail.cancelReason,
            ),
          ),
        ],
        if (detail.statusLogs.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '预约进度',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...detail.statusLogs.map(
                  (log) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2563EB),
                    ),
                    title: Text(appointmentStatusLabel(log.toStatus)),
                    subtitle: log.reason.isEmpty ? null : Text(log.reason),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (detail.availableActions.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: detail.availableActions
                .map((action) {
                  final destructive =
                      action == 'CANCEL' || action == 'REJECT_RESCHEDULE';
                  return FilledButton.tonal(
                    onPressed: () => onAction(action),
                    style: FilledButton.styleFrom(
                      foregroundColor: destructive ? Colors.red : null,
                    ),
                    child: Text(_actionLabel(action)),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = Colors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF0F172A),
                fontWeight: valueColor == null
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('返回'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      ) ??
      false;
}

String _actionLabel(String action) {
  return switch (action) {
    'CANCEL' => '取消预约',
    'ACCEPT_RESCHEDULE' => '接受新时间',
    'REJECT_RESCHEDULE' => '无法接受',
    'UNLOCK' => '蓝牙开门',
    'VIEW_PASSCODE' => '查看密码',
    'CONTACT_HOST' => '联系接待人',
    'NAVIGATE' => '导航前往',
    _ => action,
  };
}

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '待确认';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${start.year}-${two(start.month)}-${two(start.day)} '
      '${two(start.hour)}:${two(start.minute)}-'
      '${two(end.hour)}:${two(end.minute)}';
}

String _accessLabel(String status) {
  return switch (status) {
    'ACTIVE' => '已准备，可在预约时间内使用',
    'PARTIAL' => '部分凭证可用',
    'FAILED' => '准备失败，请联系平台',
    'REVOKED' || 'EXPIRED' => '已失效',
    _ => '准备中',
  };
}
