import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
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
  final _picker = ImagePicker();

  String? _frontUrl;
  String? _backUrl;
  bool _frontUploading = false;
  bool _backUploading = false;

  bool get _frontUploaded => _frontUrl?.isNotEmpty == true;
  bool get _backUploaded => _backUrl?.isNotEmpty == true;

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
                  isUploading: _frontUploading,
                  onTap: () => _pickAndUpload(isFront: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _UploadBox(
                  label: '身份证国徽面',
                  uploaded: _backUploaded,
                  isUploading: _backUploading,
                  onTap: () => _pickAndUpload(isFront: false),
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

  Future<void> _pickAndUpload({required bool isFront}) async {
    final source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    setState(() {
      if (isFront) {
        _frontUploading = true;
      } else {
        _backUploading = true;
      }
    });

    final result = await ref
        .read(rentalFlowControllerProvider.notifier)
        .uploadIdCardImage(
          filePath: image.path,
          bizType: isFront ? 'id_card_front' : 'id_card_back',
        );
    if (!mounted) return;

    setState(() {
      if (isFront) {
        _frontUploading = false;
        if (result != null) _frontUrl = result.url;
      } else {
        _backUploading = false;
        if (result != null) _backUrl = result.url;
      }
    });

    AppToast.show(
      context,
      result == null ? '身份证图片上传失败，请重试' : '${isFront ? '身份证人像面' : '身份证国徽面'}上传成功',
      type: result == null ? AppToastType.error : AppToastType.success,
    );
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
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
                children: [
                  Text('上传身份证照片', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.lg),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('拍照上传'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('从相册选择'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final idCardNumber = _idCardController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || idCardNumber.isEmpty || phone.isEmpty) {
      _showToast('请完整填写实名信息', type: AppToastType.error);
      return;
    }
    if (!_isValidMainlandIdCard(idCardNumber)) {
      _showToast('身份证号格式错误，请检查后重试', type: AppToastType.error);
      return;
    }
    if (!_frontUploaded || !_backUploaded) {
      _showToast('请上传身份证人像面和国徽面', type: AppToastType.error);
      return;
    }
    final ok = await ref
        .read(rentalFlowControllerProvider.notifier)
        .submitRealName(
          orderId: widget.orderId,
          name: name,
          idCardNumber: idCardNumber,
          phone: phone,
          idCardFrontUrl: _frontUrl!,
          idCardBackUrl: _backUrl!,
        );
    if (!mounted || !ok) return;
    context.pushReplacementNamed(
      RouteNames.leaseContract,
      pathParameters: {'orderId': widget.orderId},
    );
  }

  void _showToast(String message, {AppToastType type = AppToastType.normal}) {
    AppToast.show(context, message, type: type);
  }

  bool _isValidMainlandIdCard(String value) {
    final normalized = value.toUpperCase();
    if (!RegExp(r'^\d{17}[\dX]$').hasMatch(normalized)) return false;

    final birth = normalized.substring(6, 14);
    final year = int.tryParse(birth.substring(0, 4));
    final month = int.tryParse(birth.substring(4, 6));
    final day = int.tryParse(birth.substring(6, 8));
    if (year == null || month == null || day == null) return false;
    final birthday = DateTime(year, month, day);
    if (birthday.year != year ||
        birthday.month != month ||
        birthday.day != day) {
      return false;
    }
    if (birthday.isAfter(DateTime.now())) return false;

    const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    const checks = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
    var sum = 0;
    for (var index = 0; index < weights.length; index++) {
      sum += int.parse(normalized[index]) * weights[index];
    }
    return checks[sum % 11] == normalized[17];
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.uploaded,
    required this.isUploading,
    required this.onTap,
  });

  final String label;
  final bool uploaded;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isUploading ? null : onTap,
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
            if (isUploading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
              isUploading ? '上传中' : (uploaded ? '已上传' : '点击上传'),
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
