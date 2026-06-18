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

/// 实名认证页面。
class RealNameVerifyPage extends ConsumerStatefulWidget {
  const RealNameVerifyPage({required this.houseId, super.key});

  final String houseId;

  @override
  ConsumerState<RealNameVerifyPage> createState() => _RealNameVerifyPageState();
}

class _RealNameVerifyPageState extends ConsumerState<RealNameVerifyPage> {
  final _nameController = TextEditingController(text: '王先生');
  final _idCardController = TextEditingController(text: '110101199001011234');

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
    _idCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(rentalFlowProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('实名认证')),
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
                Text(
                  '身份信息',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: _nameController, labelText: '真实姓名'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _idCardController,
                  labelText: '身份证号',
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: RentalActionBar(
        primaryLabel: '认证并生成合同',
        isLoading: flow.isLoading,
        onPrimary: _verify,
      ),
    );
  }

  Future<void> _verify() async {
    final notifier = ref.read(rentalFlowProvider.notifier);
    final verified = await notifier.verifyRealName(
      realName: _nameController.text.trim(),
      idCardNumber: _idCardController.text.trim(),
    );
    if (!verified) return;
    final generated = await notifier.generateLeaseDraft();
    if (!mounted || !generated) return;
    context.goNamed(
      RouteNames.leaseContract,
      pathParameters: {'houseId': widget.houseId},
    );
  }
}
