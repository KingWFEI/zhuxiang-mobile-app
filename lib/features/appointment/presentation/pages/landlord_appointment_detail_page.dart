import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/appointment_models.dart';
import '../../data/providers/appointment_providers.dart';
import 'appointment_list_page.dart';

class LandlordAppointmentDetailPage extends ConsumerWidget {
  const LandlordAppointmentDetailPage({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(landlordAppointmentDetailProvider(appointmentId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('预约处理'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: FilledButton.tonal(
            onPressed: () => ref.invalidate(
              landlordAppointmentDetailProvider(appointmentId),
            ),
            child: const Text('加载失败，点击重试'),
          ),
        ),
        data: (value) => RefreshIndicator(
          key: const Key('landlord-appointment-detail-refresh'),
          onRefresh: () async {
            final refresh = ref.refresh(
              landlordAppointmentDetailProvider(appointmentId).future,
            );
            ref.invalidate(landlordAppointmentsProvider);
            await refresh;
          },
          child: _Body(
            detail: value,
            onAction: (action) => _handleAction(context, ref, value, action),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    AppointmentDetail detail,
    String action,
  ) async {
    final service = ref.read(appointmentServiceProvider);
    try {
      switch (action) {
        case 'CONFIRM':
          final result = await _confirmDialog(context);
          if (result == null) return;
          await service.landlordConfirm(
            detail.id,
            meetingPoint: result.$1,
            instruction: result.$2,
          );
          break;
        case 'REJECT':
          final reason = await _textDialog(
            context,
            title: '拒绝预约',
            hint: '请填写拒绝原因',
          );
          if (reason == null || reason.isEmpty) return;
          await service.landlordReject(detail.id, reason);
          break;
        case 'RESCHEDULE':
          final slots = await service.getViewingSlots(detail.house.id);
          if (!context.mounted) return;
          final proposal = await _rescheduleDialog(context, days: slots.dates);
          if (proposal == null) return;
          await service.landlordReschedule(
            detail.id,
            proposedStartAt: proposal.$1,
            reason: proposal.$2,
          );
          break;
        case 'CHECK_IN':
          final code = await _textDialog(
            context,
            title: '核验租客',
            hint: '请输入租客出示的 6 位核验码',
            numeric: true,
          );
          if (code == null || code.isEmpty) return;
          await service.landlordCheckIn(detail.id, code);
          break;
        case 'COMPLETE':
          await service.landlordComplete(detail.id);
          break;
        case 'NO_SHOW':
          await service.landlordNoShow(detail.id);
          break;
      }
      ref.invalidate(landlordAppointmentDetailProvider(detail.id));
      ref.invalidate(landlordAppointmentsProvider);
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

class _Body extends StatefulWidget {
  const _Body({required this.detail, required this.onAction});

  final AppointmentDetail detail;
  final Future<void> Function(String) onAction;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
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
              const SizedBox(height: 12),
              Text('状态：${appointmentStatusLabel(detail.status)}'),
              const SizedBox(height: 8),
              Text('租客：${detail.contactName} ${detail.contactPhone}'),
              const SizedBox(height: 8),
              Text('时间：${_range(detail)}'),
              if (detail.remark.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('备注：${detail.remark}'),
              ],
              if (detail.meetingPoint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('见面地点：${detail.meetingPoint}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: detail.availableActions
              .map((action) {
                return FilledButton.tonal(
                  onPressed: _busyAction != null
                      ? null
                      : () async {
                          setState(() => _busyAction = action);
                          try {
                            await widget.onAction(action);
                          } finally {
                            if (mounted) setState(() => _busyAction = null);
                          }
                        },
                  child: _busyAction == action
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_label(action)),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

Future<(DateTime, String)?> _rescheduleDialog(
  BuildContext context, {
  required List<ViewingSlotDay> days,
}) {
  final availableDays = days
      .map(
        (day) => ViewingSlotDay(
          date: day.date,
          slots: day.slots
              .where((slot) => slot.available)
              .toList(growable: false),
        ),
      )
      .where((day) => day.slots.isNotEmpty)
      .toList(growable: false);
  return showModalBottomSheet<(DateTime, String)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RescheduleSheet(days: availableDays),
  );
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({required this.days});

  final List<ViewingSlotDay> days;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  final _reasonController = TextEditingController();
  late int _selectedDayIndex;
  ViewingSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = 0;
    if (widget.days.isNotEmpty) {
      _selectedSlot = widget.days.first.slots.first;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final hasSlots = widget.days.isNotEmpty;
    final selectedDay = hasSlots ? widget.days[_selectedDayIndex] : null;
    final canSubmit =
        _selectedSlot != null && _reasonController.text.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEE9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '建议改期',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                '仅展示服务端开放且尚未被预约的时间',
                style: TextStyle(color: Color(0xFF7A8494)),
              ),
              const SizedBox(height: 20),
              if (!hasSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('近期暂无可改期时段')),
                )
              else ...[
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = widget.days[index];
                      final selected = index == _selectedDayIndex;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(_rescheduleDateLabel(day.date)),
                        onSelected: (_) {
                          setState(() {
                            _selectedDayIndex = index;
                            _selectedSlot = day.slots.first;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedDay!.slots
                      .map((slot) {
                        final selected = _selectedSlot?.startAt == slot.startAt;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(_rescheduleTimeLabel(slot)),
                          onSelected: (_) =>
                              setState(() => _selectedSlot = slot),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _reasonController,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '改期原因',
                    hintText: '请向租客说明调整原因',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSubmit
                          ? () {
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context, (
                                _selectedSlot!.startAt,
                                _reasonController.text.trim(),
                              ));
                            }
                          : null,
                      child: const Text('提交改期'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _rescheduleDateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}月${local.day}日';
}

String _rescheduleTimeLabel(ViewingSlot slot) {
  String two(int value) => value.toString().padLeft(2, '0');
  final start = slot.startAt.toLocal();
  final end = slot.endAt.toLocal();
  return '${two(start.hour)}:${two(start.minute)}-'
      '${two(end.hour)}:${two(end.minute)}';
}

Future<(String, String)?> _confirmDialog(BuildContext context) async {
  final meeting = TextEditingController();
  final instruction = TextEditingController();
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认预约'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: meeting,
            decoration: const InputDecoration(labelText: '见面地点'),
          ),
          TextField(
            controller: instruction,
            decoration: const InputDecoration(labelText: '看房说明'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            meeting.text.trim(),
            instruction.text.trim(),
          )),
          child: const Text('确认'),
        ),
      ],
    ),
  );
  meeting.dispose();
  instruction.dispose();
  return result;
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String hint,
  bool numeric = false,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('确定'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

String _range(AppointmentDetail detail) {
  final start = detail.appointmentStartAt;
  final end = detail.appointmentEndAt;
  if (start == null || end == null) return '待确认';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${start.month}月${start.day}日 '
      '${two(start.hour)}:${two(start.minute)}-'
      '${two(end.hour)}:${two(end.minute)}';
}

String _label(String action) {
  return switch (action) {
    'CONFIRM' => '接受预约',
    'REJECT' => '拒绝预约',
    'RESCHEDULE' => '建议改期',
    'CHECK_IN' => '核验到场',
    'COMPLETE' => '完成看房',
    'NO_SHOW' => '标记爽约',
    _ => action,
  };
}
