import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/lease_termination.dart';
import '../widgets/current_lease_card.dart';

class LeaseTerminationApplyPage extends ConsumerStatefulWidget {
  const LeaseTerminationApplyPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  ConsumerState<LeaseTerminationApplyPage> createState() =>
      _LeaseTerminationApplyPageState();
}

class _LeaseTerminationApplyPageState
    extends ConsumerState<LeaseTerminationApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _remarkController = TextEditingController();
  final _picker = ImagePicker();
  final List<LeaseTerminationAttachment> _attachments = [];
  DateTime? _expectedMoveOutDate;
  bool _hasMovedOut = false;
  bool _isSubmitting = false;
  bool _isUploadingAttachment = false;
  bool _didFillLeaseInfo = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(leaseDetailProvider(widget.leaseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('申请退租')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: detail.when(
            loading: () => const AppLoadingView(message: '正在加载租约信息'),
            error: (error, stackTrace) => AppApiErrorView(
              error: error,
              message: '租约信息加载失败',
              onRetry: () =>
                  ref.invalidate(leaseDetailProvider(widget.leaseId)),
            ),
            data: (lease) {
              _fillLeaseInfoOnce(lease);
              return _buildForm(lease);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Lease lease) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          _NoticeCard(message: '退租申请提交后不会立即终止合同，需等待管家审核、验房和费用结算。'),
          const SizedBox(height: AppSpacing.md),
          _CardSection(
            title: '租约信息',
            child: Column(
              children: [
                _InfoRow(label: '房源', value: lease.houseName),
                _InfoRow(
                  label: '租期',
                  value:
                      '${formatLeaseDate(lease.startDate)} - ${formatLeaseDate(lease.endDate)}',
                ),
                _InfoRow(
                  label: '押金',
                  value: '¥${formatLeaseMoney(lease.deposit)}',
                ),
                _InfoRow(label: '账单状态', value: lease.billStatus.label),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CardSection(
            title: '退租信息',
            child: Column(
              children: [
                TextFormField(
                  controller: _reasonController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '退租原因',
                    hintText: '请填写退租原因，例如工作变动、换房等',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 2) return '请填写退租原因';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_formatDate(_expectedMoveOutDate)),
                  subtitle: const Text('期望退租日期'),
                  trailing: const Icon(Icons.event_rounded),
                  onTap: _pickMoveOutDate,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _hasMovedOut,
                  title: const Text('我已搬离'),
                  subtitle: const Text('如已搬离，请补充房屋现状照片'),
                  onChanged: (value) => setState(() => _hasMovedOut = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CardSection(
            title: '补充材料',
            child: _ImagePlaceholder(
              attachments: _attachments,
              isUploading: _isUploadingAttachment,
              onAdd: _pickAndUploadAttachment,
              onRemove: (attachment) =>
                  setState(() => _attachments.remove(attachment)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CardSection(
            title: '联系方式',
            child: Column(
              children: [
                TextFormField(
                  controller: _contactNameController,
                  decoration: const InputDecoration(
                    labelText: '联系人',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? '请输入联系人' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '联系电话',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return '请输入联系电话';
                    if (text.length < 7) return '联系电话格式不正确';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _remarkController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '可填写希望验房时间、钥匙交接方式等',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : () => _submit(lease),
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('提交退租申请'),
            ),
          ),
        ],
      ),
    );
  }

  void _fillLeaseInfoOnce(Lease lease) {
    if (_didFillLeaseInfo) return;
    _contactNameController.text = lease.tenantName;
    _contactPhoneController.text = lease.tenantPhone;
    _expectedMoveOutDate = DateTime.now().add(const Duration(days: 7));
    _didFillLeaseInfo = true;
  }

  Future<void> _pickMoveOutDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedMoveOutDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked == null) return;
    setState(() => _expectedMoveOutDate = picked);
  }

  Future<void> _submit(Lease lease) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingAttachment) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('照片正在上传，请稍后提交')));
      return;
    }
    if (_expectedMoveOutDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择期望退租日期')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(leaseServiceProvider);

      // 1. 查询是否已有退租申请
      final current = await service.getCurrentTermination(widget.leaseId);
      if (!mounted) return;
      if (current != null) {
        await _showExistingTerminationDialog(current);
        if (!mounted) return;
        context.pushReplacementNamed(
          RouteNames.moveOutInspection,
          pathParameters: {'leaseId': widget.leaseId},
        );
        return;
      }

      // 2. 调用 check 检查是否可以退租
      final check = await service.checkTermination(widget.leaseId);
      if (!mounted) return;
      if (!check.canApply) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              check.message.isNotEmpty ? check.message : '当前不可提交退租申请',
            ),
          ),
        );
        return;
      }

      // 3. 提交退租申请
      final body = <String, dynamic>{
        'reason': _reasonController.text.trim(),
        'expectedMoveOutDate': LeaseTerminationRequest.formatDate(
          _expectedMoveOutDate!,
        ),
        'hasMovedOut': _hasMovedOut,
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'remark': _remarkController.text.trim(),
        'attachments': _attachments.map((item) => item.toJson()).toList(),
      };

      final application = await service.applyTermination(widget.leaseId, body);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('申请已提交'),
          content: Text('退租申请已进入${application.statusText}，管家会尽快审核并联系你安排后续流程。'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      ref.invalidate(leaseDetailProvider(widget.leaseId));
      context.pushReplacementNamed(
        RouteNames.moveOutInspection,
        pathParameters: {'leaseId': widget.leaseId},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error, '退租申请提交失败，请稍后重试'))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showExistingTerminationDialog(
    TerminationApplication application,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已提交退租申请'),
        content: Text(
          '当前租约已有退租申请（${application.applicationNo}），状态为${application.statusText}，请等待管家处理。',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAttachment() async {
    if (_isUploadingAttachment) return;
    final source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingAttachment = true);
    try {
      final attachment = await ref
          .read(leaseServiceProvider)
          .uploadTerminationAttachment(
            filePath: image.path,
            fileName: image.name.isEmpty ? '退租材料.jpg' : image.name,
          );
      if (!mounted) return;
      setState(() => _attachments.add(attachment));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('照片上传成功')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error, '照片上传失败，请重试'))));
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
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
                  Text('上传退租材料', style: AppTextStyles.titleMedium),
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

  String _message(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? fallback : message;
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.attachments,
    required this.isUploading,
    required this.onAdd,
    required this.onRemove,
  });

  final List<LeaseTerminationAttachment> attachments;
  final bool isUploading;
  final VoidCallback onAdd;
  final ValueChanged<LeaseTerminationAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final attachment in attachments)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.network(
                    attachment.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.image_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: InkWell(
                  onTap: () => onRemove(attachment),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (isUploading)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        InkWell(
          onTap: isUploading ? null : onAdd,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add_a_photo_rounded),
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '请选择期望退租日期';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
