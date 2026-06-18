import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/rental_flow_models.dart';
import '../providers/rental_flow_providers.dart';
import '../widgets/rental_action_bar.dart';
import '../widgets/rental_flow_stepper.dart';
import '../widgets/rental_status_card.dart';

/// 预约看房页面。
class ViewingAppointmentPage extends ConsumerStatefulWidget {
  const ViewingAppointmentPage({
    required this.houseId,
    required this.houseTitle,
    super.key,
  });

  final String houseId;
  final String houseTitle;

  @override
  ConsumerState<ViewingAppointmentPage> createState() =>
      _ViewingAppointmentPageState();
}

class _ViewingAppointmentPageState
    extends ConsumerState<ViewingAppointmentPage> {
  final _nameController = TextEditingController(text: '王先生');
  final _phoneController = TextEditingController(text: '13800000000');
  final _remarkController = TextEditingController();
  ViewingType _viewingType = ViewingType.offline;
  DateTime _appointmentDate = DateTime.now().add(const Duration(days: 1));
  String _timeRange = '10:00-11:00';

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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(rentalFlowProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('预约看房')),
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
          RentalStatusCard(state: flow, title: widget.houseTitle),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: '看房方式',
            child: SegmentedButton<ViewingType>(
              segments: const [
                ButtonSegment(
                  value: ViewingType.offline,
                  label: Text('线下看房'),
                  icon: Icon(Icons.storefront_outlined),
                ),
                ButtonSegment(
                  value: ViewingType.online,
                  label: Text('视频看房'),
                  icon: Icon(Icons.videocam_outlined),
                ),
              ],
              selected: {_viewingType},
              onSelectionChanged: (value) {
                setState(() => _viewingType = value.first);
              },
            ),
          ),
          _Section(
            title: '看房日期',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(_formatDate(_appointmentDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
          ),
          _Section(
            title: '时间段',
            child: Wrap(
              spacing: AppSpacing.sm,
              children: ['10:00-11:00', '14:00-15:00', '19:00-20:00']
                  .map(
                    (time) => ChoiceChip(
                      label: Text(time),
                      selected: _timeRange == time,
                      onSelected: (_) => setState(() => _timeRange = time),
                    ),
                  )
                  .toList(),
            ),
          ),
          _Section(
            title: '联系人',
            child: Column(
              children: [
                AppTextField(controller: _nameController, labelText: '联系人'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phoneController,
                  labelText: '手机号',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _remarkController, labelText: '备注'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: RentalActionBar(
        primaryLabel: '提交预约',
        isLoading: flow.isLoading,
        onPrimary: _submit,
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) setState(() => _appointmentDate = date);
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(rentalFlowProvider.notifier)
        .bookViewing(
          houseTitle: widget.houseTitle,
          viewingType: _viewingType,
          appointmentDate: _appointmentDate,
          appointmentTimeRange: _timeRange,
          contactName: _nameController.text.trim(),
          contactPhone: _phoneController.text.trim(),
          remark: _remarkController.text.trim(),
        );
    if (!mounted || !ok) return;
    context.goNamed(
      RouteNames.viewingDetail,
      pathParameters: {'houseId': widget.houseId},
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
