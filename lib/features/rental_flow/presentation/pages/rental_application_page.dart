import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/rental_flow_providers.dart';
import '../widgets/rental_action_bar.dart';
import '../widgets/rental_flow_stepper.dart';
import '../widgets/rental_status_card.dart';

/// 租房申请页面。
class RentalApplicationPage extends ConsumerStatefulWidget {
  const RentalApplicationPage({required this.houseId, super.key});

  final String houseId;

  @override
  ConsumerState<RentalApplicationPage> createState() =>
      _RentalApplicationPageState();
}

class _RentalApplicationPageState extends ConsumerState<RentalApplicationPage> {
  final _tenantNameController = TextEditingController(text: '王先生');
  final _tenantPhoneController = TextEditingController(text: '13800000000');
  final _emergencyNameController = TextEditingController(text: '李女士');
  final _emergencyPhoneController = TextEditingController(text: '13900000000');
  DateTime _moveInDate = DateTime.now().add(const Duration(days: 7));
  int _leaseMonths = 12;
  String _paymentCycle = '月付';
  bool _hasPet = false;

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
    _tenantNameController.dispose();
    _tenantPhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(rentalFlowProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('租房申请')),
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
          _Card(
            title: '入住信息',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(_formatDate(_moveInDate)),
                  subtitle: const Text('入住时间'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickMoveInDate,
                ),
                Row(
                  children: [
                    const Text('租期'),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 24,
                        divisions: 23,
                        value: _leaseMonths.toDouble(),
                        label: '$_leaseMonths 个月',
                        onChanged: (value) {
                          setState(() => _leaseMonths = value.round());
                        },
                      ),
                    ),
                    Text('$_leaseMonths 个月'),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _paymentCycle,
                  decoration: const InputDecoration(labelText: '付款方式'),
                  items: ['月付', '季付', '半年付']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentCycle = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('是否有宠物'),
                  value: _hasPet,
                  onChanged: (value) => setState(() => _hasPet = value),
                ),
              ],
            ),
          ),
          _Card(
            title: '申请人信息',
            child: Column(
              children: [
                AppTextField(
                  controller: _tenantNameController,
                  labelText: '姓名',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _tenantPhoneController,
                  labelText: '手机号',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emergencyNameController,
                  labelText: '紧急联系人',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emergencyPhoneController,
                  labelText: '紧急联系人手机号',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: RentalActionBar(
        primaryLabel: '提交申请',
        isLoading: flow.isLoading,
        onPrimary: _submit,
      ),
    );
  }

  Future<void> _pickMoveInDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _moveInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date != null) setState(() => _moveInDate = date);
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(rentalFlowProvider.notifier)
        .submitApplication(
          tenantName: _tenantNameController.text.trim(),
          tenantPhone: _tenantPhoneController.text.trim(),
          moveInDate: _moveInDate,
          leaseMonths: _leaseMonths,
          paymentCycle: _paymentCycle,
          hasPet: _hasPet,
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
        );
    if (!mounted || !ok) return;
    context.goNamed(
      RouteNames.realNameVerify,
      pathParameters: {'houseId': widget.houseId},
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

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
