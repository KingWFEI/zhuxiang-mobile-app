import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/providers/profile_providers.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _nicknameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _newPhoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  bool _passwordVisible = false;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isChangingPassword = false;
  bool _isChangingPhone = false;
  bool _isSendingCode = false;

  String? _avatarUrl;

  @override
  void dispose() {
    _nicknameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPhoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    // 初始化：仅首次加载时从 user 填充
    if (_nicknameController.text.isEmpty && user.nickname.isNotEmpty) {
      _nicknameController.text = user.nickname;
    }
    _avatarUrl ??= user.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('个人信息'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          _ProfileEditCard(
            avatarUrl: _avatarUrl,
            isUploading: _isUploadingAvatar,
            onPickAvatar: _handlePickAvatar,
            nicknameController: _nicknameController,
            isSaving: _isSavingProfile,
            onSave: _handleSaveProfile,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: user.hasPassword ? '修改密码' : '设置密码',
            children: [
              if (user.hasPassword) ...[
                _PasswordField(
                  controller: _oldPasswordController,
                  hintText: '请输入旧密码',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _PasswordField(
                controller: _newPasswordController,
                hintText: '请输入新密码（6-32位）',
              ),
              const SizedBox(height: AppSpacing.md),
              _PasswordField(
                controller: _confirmPasswordController,
                hintText: '请再次输入新密码',
                onVisibilityToggle: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                visible: _passwordVisible,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isChangingPassword
                      ? null
                      : user.hasPassword
                      ? _handleChangePassword
                      : _handleSetPassword,
                  child: _isChangingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(user.hasPassword ? '修改密码' : '设置密码'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: '修改手机号',
            children: [
              TextField(
                controller: _newPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  hintText: '请输入新手机号',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        hintText: '验证码',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 112,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isSendingCode ? null : _handleSendCode,
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('获取验证码'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isChangingPhone ? null : _handleChangePhone,
                  child: _isChangingPhone
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('修改手机号'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      AppToast.show(context, '请输入旧密码', type: AppToastType.error);
      return;
    }
    if (newPassword.isEmpty) {
      AppToast.show(context, '请输入新密码', type: AppToastType.error);
      return;
    }
    if (newPassword.length < 6 || newPassword.length > 32) {
      AppToast.show(context, '新密码长度需为6-32位', type: AppToastType.error);
      return;
    }
    if (newPassword != confirmPassword) {
      AppToast.show(context, '两次输入的新密码不一致', type: AppToastType.error);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await ref
          .read(profileServiceProvider)
          .changePassword(oldPassword: oldPassword, newPassword: newPassword);
      if (!mounted) return;
      AppToast.show(context, '密码修改成功', type: AppToastType.success);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '密码修改失败';
      AppToast.show(context, message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _handleSetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      AppToast.show(context, '请输入新密码', type: AppToastType.error);
      return;
    }
    if (newPassword.length < 6 || newPassword.length > 32) {
      AppToast.show(context, '新密码长度需为6-32位', type: AppToastType.error);
      return;
    }
    if (newPassword != confirmPassword) {
      AppToast.show(context, '两次输入的新密码不一致', type: AppToastType.error);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await ref
          .read(profileServiceProvider)
          .setPassword(newPassword: newPassword);
      final user = ref.read(authControllerProvider).user;
      if (user != null) {
        await ref
            .read(authControllerProvider.notifier)
            .updateUser(
              AuthUser(
                id: user.id,
                phone: user.phone,
                nickname: user.nickname,
                avatarUrl: user.avatarUrl,
                isVerified: user.isVerified,
                role: user.role,
                hasPassword: true,
              ),
            );
      }
      if (!mounted) return;
      AppToast.show(context, '密码设置成功', type: AppToastType.success);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '密码设置失败';
      AppToast.show(context, message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _handleSendCode() async {
    final phone = _newPhoneController.text.trim();
    if (phone.length != 11) {
      AppToast.show(context, '请输入正确的手机号', type: AppToastType.error);
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final expiresIn = await ref
          .read(authControllerProvider.notifier)
          .sendSmsCode(phone: phone, scene: 'login');
      if (!mounted) return;
      if (expiresIn != null) {
        AppToast.show(context, '验证码已发送', type: AppToastType.success);
      }
    } on Object {
      // error handled by auth controller
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _handleChangePhone() async {
    final newPhone = _newPhoneController.text.trim();
    final code = _smsCodeController.text.trim();

    if (newPhone.length != 11) {
      AppToast.show(context, '请输入正确的手机号', type: AppToastType.error);
      return;
    }
    if (code.length != 6) {
      AppToast.show(context, '请输入6位验证码', type: AppToastType.error);
      return;
    }

    setState(() => _isChangingPhone = true);
    try {
      final data = await ref
          .read(profileServiceProvider)
          .changePhone(newPhone: newPhone, code: code);
      await ref
          .read(authControllerProvider.notifier)
          .updateUser(AuthUser.fromJson(data));
      if (!mounted) return;
      AppToast.show(context, '手机号修改成功', type: AppToastType.success);
      _newPhoneController.clear();
      _smsCodeController.clear();
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '手机号修改失败';
      AppToast.show(context, message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isChangingPhone = false);
    }
  }

  Future<void> _handlePickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final url = await ref
          .read(profileServiceProvider)
          .uploadAvatar(image.path);
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _isUploadingAvatar = false;
      });
      AppToast.show(context, '头像上传成功', type: AppToastType.success);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '头像上传失败';
      AppToast.show(context, message, type: AppToastType.error);
    }
  }

  Future<void> _handleSaveProfile() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      AppToast.show(context, '请输入昵称', type: AppToastType.error);
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final data = await ref
          .read(profileServiceProvider)
          .updateProfile(nickname: nickname, avatarUrl: _avatarUrl);
      // 同步更新全局用户状态
      await ref
          .read(authControllerProvider.notifier)
          .updateUser(AuthUser.fromJson(data));
      if (!mounted) return;
      AppToast.show(context, '个人信息已更新', type: AppToastType.success);
    } on Object catch (e) {
      if (!mounted) return;
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '更新失败';
      AppToast.show(context, message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }
}

class _ProfileEditCard extends StatelessWidget {
  const _ProfileEditCard({
    required this.avatarUrl,
    required this.isUploading,
    required this.onPickAvatar,
    required this.nicknameController,
    required this.isSaving,
    required this.onSave,
  });

  final String? avatarUrl;
  final bool isUploading;
  final VoidCallback onPickAvatar;
  final TextEditingController nicknameController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // 头像
          GestureDetector(
            onTap: isUploading ? null : onPickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 42,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('点击更换头像', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          // 昵称
          TextField(
            controller: nicknameController,
            decoration: const InputDecoration(
              labelText: '昵称',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    this.visible,
    this.onVisibilityToggle,
  });

  final TextEditingController controller;
  final String hintText;
  final bool? visible;
  final VoidCallback? onVisibilityToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !(visible ?? false),
      inputFormatters: [LengthLimitingTextInputFormatter(32)],
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: onVisibilityToggle != null
            ? IconButton(
                icon: Icon(
                  (visible ?? false) ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }
}
