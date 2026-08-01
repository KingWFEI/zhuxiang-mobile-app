import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/landlord_profile.dart';
import '../../data/providers/landlord_providers.dart';

class LandlordProfileEditPage extends ConsumerStatefulWidget {
  const LandlordProfileEditPage({super.key});

  @override
  ConsumerState<LandlordProfileEditPage> createState() =>
      _LandlordProfileEditPageState();
}

class _LandlordProfileEditPageState
    extends ConsumerState<LandlordProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slogan = TextEditingController();
  final _introduction = TextEditingController();
  final _serviceArea = TextEditingController();
  final _serviceYears = TextEditingController();
  final _tags = TextEditingController();
  final _phone = TextEditingController();
  final _wechat = TextEditingController();
  final _email = TextEditingController();
  final _contactTime = TextEditingController();
  final _response = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _showPhone = false;
  bool _showWechat = false;
  bool _showEmail = false;
  bool _uploadingCover = false;
  String _coverImageUrl = '';

  @override
  void dispose() {
    for (final controller in [
      _name,
      _slogan,
      _introduction,
      _serviceArea,
      _serviceYears,
      _tags,
      _phone,
      _wechat,
      _email,
      _contactTime,
      _response,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fill(LandlordProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _name.text = profile.name;
    _slogan.text = profile.slogan;
    _introduction.text = profile.introduction;
    _serviceArea.text = profile.serviceArea;
    _serviceYears.text = profile.serviceYears.toString();
    _tags.text = profile.profileTags.join('、');
    _phone.text = profile.phone ?? '';
    _wechat.text = profile.wechat ?? '';
    _email.text = profile.email ?? '';
    _contactTime.text = profile.contactTime;
    _response.text = profile.responseDescription;
    _showPhone = profile.showPhone;
    _showWechat = profile.showWechat;
    _showEmail = profile.showEmail;
    _coverImageUrl = profile.coverImageUrl;
  }

  Future<void> _pickCover() async {
    if (_uploadingCover) return;
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (image == null || !mounted) return;
    setState(() => _uploadingCover = true);
    try {
      final url = await ref
          .read(landlordHouseServiceProvider)
          .uploadImage(image.path, image.name);
      if (mounted) setState(() => _coverImageUrl = url);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('封面上传失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final tags = _tags.text
          .split(RegExp(r'[,，、]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .take(8)
          .toList();
      await ref
          .read(landlordProfileServiceProvider)
          .updateMyProfile(
            UpdateLandlordProfileRequest(
              name: _name.text.trim(),
              coverImageUrl: _coverImageUrl,
              slogan: _slogan.text.trim(),
              introduction: _introduction.text.trim(),
              serviceArea: _serviceArea.text.trim(),
              serviceYears: int.tryParse(_serviceYears.text.trim()) ?? 0,
              profileTags: tags,
              phone: _phone.text.trim(),
              wechat: _wechat.text.trim(),
              email: _email.text.trim(),
              contactTime: _contactTime.text.trim(),
              responseDescription: _response.text.trim(),
              showPhone: _showPhone,
              showWechat: _showWechat,
              showEmail: _showEmail,
            ),
          );
      ref.invalidate(myLandlordProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('房东公开资料已保存')));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myLandlordProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('房东公开资料'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中' : '保存'),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(myLandlordProfileProvider),
        ),
        data: (data) {
          _fill(data);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                const _SectionTitle(title: '主页展示', subtitle: '这些内容会展示在你的房源详情中'),
                _CoverPicker(
                  imageUrl: _coverImageUrl,
                  uploading: _uploadingCover,
                  onTap: _pickCover,
                  onRemove: _coverImageUrl.isEmpty
                      ? null
                      : () => setState(() => _coverImageUrl = ''),
                ),
                const SizedBox(height: AppSpacing.md),
                _field(
                  _name,
                  '展示名称',
                  maxLength: 50,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '请输入展示名称' : null,
                ),
                _field(_slogan, '一句话介绍', maxLength: 120),
                _field(_introduction, '个人介绍', maxLength: 1000, maxLines: 5),
                _field(_serviceArea, '服务区域', maxLength: 200),
                _field(
                  _serviceYears,
                  '服务年限',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final years = int.tryParse(value?.trim() ?? '');
                    if (years == null || years < 0 || years > 80) {
                      return '请输入 0 到 80 之间的年限';
                    }
                    return null;
                  },
                ),
                _field(
                  _tags,
                  '服务标签',
                  hint: '例如：响应及时、熟悉本地、可养宠',
                  helper: '使用逗号或顿号分隔，最多 8 个',
                ),
                _field(
                  _response,
                  '响应说明',
                  hint: '例如：工作日 10 分钟内回复',
                  maxLength: 100,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(
                  title: '联系信息',
                  subtitle: '填写不等于公开，每种方式可单独控制',
                ),
                _contactField(
                  controller: _phone,
                  label: '联系电话',
                  value: _showPhone,
                  onChanged: (value) => setState(() => _showPhone = value),
                  keyboardType: TextInputType.phone,
                ),
                _contactField(
                  controller: _wechat,
                  label: '微信号',
                  value: _showWechat,
                  onChanged: (value) => setState(() => _showWechat = value),
                ),
                _contactField(
                  controller: _email,
                  label: '联系邮箱',
                  value: _showEmail,
                  onChanged: (value) => setState(() => _showEmail = value),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isNotEmpty && !text.contains('@')) {
                      return '邮箱格式不正确';
                    }
                    return null;
                  },
                ),
                _field(
                  _contactTime,
                  '方便联系的时间',
                  hint: '例如：每天 09:00—21:00',
                  maxLength: 100,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? helper,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _contactField({
    required TextEditingController controller,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (text) {
          if (value && (text == null || text.trim().isEmpty)) {
            return '公开前请先填写$label';
          }
          return validator?.call(text);
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('公开', style: TextStyle(fontSize: 12)),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.imageUrl,
    required this.uploading,
    required this.onTap,
    required this.onRemove,
  });

  final String imageUrl;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: AppColors.primaryLight),
              )
            else
              Container(
                color: AppColors.primaryLight,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primary,
                      size: 34,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text('添加主页封面', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: uploading ? null : onTap),
            ),
            if (uploading)
              Container(
                color: Colors.black38,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white),
              ),
            if (onRemove != null && !uploading)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: IconButton.filledTonal(
                  tooltip: '移除封面',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
