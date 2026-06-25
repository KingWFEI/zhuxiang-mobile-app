import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/providers/rental_flow_providers.dart';
import '../../domain/entities/rental_flow_step.dart';
import '../widgets/rental_flow_bottom_bar.dart';
import '../widgets/rental_flow_page_shell.dart';

class RealNameVerifyPage extends ConsumerStatefulWidget {
  const RealNameVerifyPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<RealNameVerifyPage> createState() => _RealNameVerifyPageState();
}

class _RealNameVerifyPageState extends ConsumerState<RealNameVerifyPage> {
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _frontUploaded = false;
  bool _backUploaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalFlowControllerProvider);
    return RentalFlowPageShell(
      title: '实名认证',
      step: RentalFlowStep.realName,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      onRetry: _load,
      bottomNavigationBar: RentalFlowBottomBar(
        primaryLabel: '提交认证',
        isLoading: state.isSubmitting,
        onPrimary: _submit,
      ),
      children: [
        const FlowCard(
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.primary),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('为保障租住安全，请完成实名认证')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '身份信息',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _nameController, labelText: '姓名'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _idCardController, labelText: '身份证号'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                labelText: '手机号',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FlowCard(
          child: Row(
            children: [
              Expanded(
                child: _UploadBox(
                  label: '身份证人像面',
                  uploaded: _frontUploaded,
                  onTap: () => _mockUpload(isFront: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _UploadBox(
                  label: '身份证国徽面',
                  uploaded: _backUploaded,
                  onTap: () => _mockUpload(isFront: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _load() {
    ref
        .read(rentalFlowControllerProvider.notifier)
        .loadRentOrder(widget.orderId);
  }

  Future<void> _mockUpload({required bool isFront}) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '上传${isFront ? '身份证人像面' : '身份证国徽面'}',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '当前先使用 Mock 上传占位，后续接入相册/拍照后替换为真实图片上传。',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('模拟上传'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      if (isFront) {
        _frontUploaded = true;
      } else {
        _backUploaded = true;
      }
    });
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _idCardController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请完整填写实名信息')));
      return;
    }
    if (!_frontUploaded || !_backUploaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请上传身份证人像面和国徽面')));
      return;
    }
    final ok = await ref
        .read(rentalFlowControllerProvider.notifier)
        .submitRealName(
          orderId: widget.orderId,
          name: _nameController.text.trim(),
          idCardNumber: _idCardController.text.trim(),
          phone: _phoneController.text.trim(),
        );
    if (!mounted || !ok) return;
    context.pushReplacementNamed(
      RouteNames.leaseContract,
      pathParameters: {'orderId': widget.orderId},
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.uploaded,
    required this.onTap,
  });

  final String label;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: uploaded ? const Color(0xFFEAF8EF) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: uploaded ? AppColors.success : AppColors.primarySoft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              uploaded
                  ? Icons.check_circle_outline
                  : Icons.add_a_photo_outlined,
              color: uploaded ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              uploaded ? '已上传' : '点击上传',
              style: AppTextStyles.bodySmall.copyWith(
                color: uploaded ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
