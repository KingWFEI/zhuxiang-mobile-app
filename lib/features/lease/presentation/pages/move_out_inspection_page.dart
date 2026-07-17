import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/inspection_providers.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/inspection.dart';
import '../../domain/entities/lease.dart';

class MoveOutInspectionPage extends ConsumerStatefulWidget {
  const MoveOutInspectionPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  ConsumerState<MoveOutInspectionPage> createState() =>
      _MoveOutInspectionPageState();
}

class _MoveOutInspectionPageState extends ConsumerState<MoveOutInspectionPage> {
  final _picker = ImagePicker();
  MoveOutInspection? _inspection;
  String? _uploadingItemCode;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final lease = ref.watch(leaseDetailProvider(widget.leaseId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('退租验房照片')),
      body: lease.when(
        loading: () => const AppLoadingView(message: '正在加载租约信息'),
        error: (error, stackTrace) => AppErrorView(
          message: '租约信息加载失败',
          onRetry: () => ref.invalidate(leaseDetailProvider(widget.leaseId)),
        ),
        data: (value) => _buildInspection(context, value),
      ),
    );
  }

  Widget _buildInspection(BuildContext context, Lease lease) {
    if (lease.contractId.isEmpty) {
      return const AppErrorView(message: '当前租约缺少合同信息，无法上传验房照片');
    }

    final remote = ref.watch(moveOutInspectionProvider(lease.contractId));
    return remote.when(
      loading: () => const AppLoadingView(message: '正在加载验房清单'),
      error: (error, stackTrace) => AppErrorView(
        message: '验房清单加载失败',
        onRetry: () =>
            ref.invalidate(moveOutInspectionProvider(lease.contractId)),
      ),
      data: (value) {
        _inspection ??= value;
        return _buildContent(context, lease, _inspection!);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Lease lease,
    MoveOutInspection inspection,
  ) {
    final locked = !inspection.canEdit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        _StatusCard(inspection: inspection),
        const SizedBox(height: AppSpacing.md),
        Text(lease.houseName, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          locked ? '现场验房已完成，照片已归档' : '请按照验房清单拍摄现场照片，提交后由管理端归档',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final room in inspection.rooms) ...[
          _RoomSection(
            room: room,
            locked: locked,
            uploadingItemCode: _uploadingItemCode,
            onAddPhoto: (item) => _pickAndUpload(
              contractId: inspection.contractId,
              room: room,
              item: item,
            ),
            onRemovePhoto: locked
                ? null
                : (item, photo) => _removePhoto(room, item, photo),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (inspection.rooms.isEmpty)
          const _EmptyCard(message: '管理端暂未配置退租验房清单'),
        if (!locked && inspection.rooms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(inspection),
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isSubmitting ? '正在提交' : '提交验房照片'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUpload({
    required String contractId,
    required InspectionRoom room,
    required InspectionItem item,
  }) async {
    if (_uploadingItemCode != null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    );
    if (source == null || !mounted) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;

    setState(() => _uploadingItemCode = item.itemCode);
    try {
      final photo = await ref
          .read(inspectionServiceProvider)
          .uploadPhoto(
            filePath: image.path,
            fileName: image.name.isEmpty ? 'move-out.jpg' : image.name,
          );
      if (!mounted) return;
      _replaceItem(
        room.roomCode,
        item.copyWith(photos: [...item.photos, photo]),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('照片上传成功')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('照片上传失败：$error')));
    } finally {
      if (mounted) setState(() => _uploadingItemCode = null);
    }
  }

  void _removePhoto(
    InspectionRoom room,
    InspectionItem item,
    InspectionPhoto photo,
  ) {
    _replaceItem(
      room.roomCode,
      item.copyWith(
        photos: item.photos.where((value) => value != photo).toList(),
      ),
    );
  }

  void _replaceItem(String roomCode, InspectionItem updated) {
    final current = _inspection;
    if (current == null) return;
    final rooms = current.rooms.map((room) {
      if (room.roomCode != roomCode) return room;
      return InspectionRoom(
        roomCode: room.roomCode,
        roomName: room.roomName,
        items: room.items
            .map((item) => item.itemCode == updated.itemCode ? updated : item)
            .toList(),
      );
    }).toList();
    setState(() {
      _inspection = MoveOutInspection(
        contractId: current.contractId,
        status: current.status,
        rooms: rooms,
        completedAt: current.completedAt,
        completionComment: current.completionComment,
      );
    });
  }

  Future<void> _submit(MoveOutInspection inspection) async {
    final missing = [
      for (final room in inspection.rooms)
        for (final item in room.items)
          if (item.required && item.photos.length < item.minPhotoCount)
            '${room.roomName}-${item.itemName}',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请补充必拍照片：${missing.join('、')}')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ref
          .read(inspectionServiceProvider)
          .submitMoveOutInspection(
            contractId: inspection.contractId,
            rooms: inspection.rooms,
          );
      if (!mounted) return;
      setState(() => _inspection = result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('验房照片已提交，等待管理端归档')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提交失败：$error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.inspection});

  final MoveOutInspection inspection;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (inspection.status) {
      MoveOutInspectionStatus.draft => (
        '待上传照片',
        AppColors.warning,
        Icons.photo_camera_outlined,
      ),
      MoveOutInspectionStatus.submitted => (
        '照片已提交，等待归档',
        AppColors.primary,
        Icons.cloud_upload_outlined,
      ),
      MoveOutInspectionStatus.locked => (
        '现场验房已完成',
        AppColors.success,
        Icons.verified_outlined,
      ),
      MoveOutInspectionStatus.unknown => (
        '状态未知',
        AppColors.warning,
        Icons.help_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.titleMedium)),
        ],
      ),
    );
  }
}

class _RoomSection extends StatelessWidget {
  const _RoomSection({
    required this.room,
    required this.locked,
    required this.uploadingItemCode,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final InspectionRoom room;
  final bool locked;
  final String? uploadingItemCode;
  final ValueChanged<InspectionItem> onAddPhoto;
  final void Function(InspectionItem, InspectionPhoto)? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.roomName, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in room.items)
            _InspectionItemTile(
              item: item,
              locked: locked,
              uploading: uploadingItemCode == item.itemCode,
              onAddPhoto: () => onAddPhoto(item),
              onRemovePhoto: onRemovePhoto == null
                  ? null
                  : (photo) => onRemovePhoto!(item, photo),
            ),
        ],
      ),
    );
  }
}

class _InspectionItemTile extends StatelessWidget {
  const _InspectionItemTile({
    required this.item,
    required this.locked,
    required this.uploading,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final InspectionItem item;
  final bool locked;
  final bool uploading;
  final VoidCallback onAddPhoto;
  final ValueChanged<InspectionPhoto>? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final enough = item.photos.length >= item.minPhotoCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.itemName}${item.required ? ' · 必拍' : ''}',
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              Text(
                '${item.photos.length}/${item.minPhotoCount}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: enough ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          if (item.instruction?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.instruction!, style: AppTextStyles.bodySmall),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final photo in item.photos)
                _PhotoThumb(
                  photo: photo,
                  onRemove: onRemovePhoto == null
                      ? null
                      : () => onRemovePhoto!(photo),
                ),
              if (!locked)
                InkWell(
                  onTap: uploading ? null : onAddPhoto,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: uploading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, this.onRemove});

  final InspectionPhoto photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            photo.url,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: AppColors.primaryLight,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -8,
            right: -8,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
