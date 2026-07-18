import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/role_navigation_config.dart';
import '../../../../app/router/app_mode_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/auth_agreement_row.dart';
import '../widgets/auth_page_header.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../providers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hasAgreed = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height,
            ),
            child: Column(
              children: [
                const AuthPageHeader(title: '欢迎注册', subtitle: '创建账号，开启安心入住体验'),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: _RegisterFormPanel(
                    nicknameController: _nicknameController,
                    phoneController: _phoneController,
                    codeController: _codeController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    hasAgreed: _hasAgreed,
                    showPassword: _showPassword,
                    showConfirmPassword: _showConfirmPassword,
                    onAgreementChanged: (value) {
                      setState(() => _hasAgreed = value);
                    },
                    onPasswordVisibilityChanged: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                    onConfirmPasswordVisibilityChanged: () {
                      setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      );
                    },
                    onRegister: _handleRegister,
                    onGetCode: _handleGetCode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final nickname = _nicknameController.text.trim();
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (phone.isEmpty) {
      _showMessage('请输入手机号');
      return;
    }
    if (phone.length != 11) {
      _showMessage('请输入正确的手机号');
      return;
    }
    if (nickname.isEmpty) {
      _showMessage('请输入昵称');
      return;
    }
    if (code.length != 6) {
      _showMessage('请输入6位验证码');
      return;
    }
    if (password.length < 6 || password.length > 32) {
      _showMessage('密码长度应为6-32位');
      return;
    }
    if (confirmPassword.isEmpty) {
      _showMessage('请确认密码');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('两次输入的密码不一致');
      return;
    }
    if (!_hasAgreed) {
      _showMessage('请先阅读并同意用户协议和隐私政策');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          phone: phone,
          code: code,
          password: password,
          nickname: nickname,
        );
    if (!mounted) return;
    if (success) {
      _showMessage('注册成功');
      context.go(_entryLocation());
      return;
    }

    final message =
        ref.read(authControllerProvider).errorMessage ?? '注册失败，请稍后重试';
    _showMessage(message);
  }

  Future<void> _handleGetCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      _showMessage('请输入正确的手机号');
      return;
    }

    final expiresIn = await ref
        .read(authControllerProvider.notifier)
        .sendSmsCode(phone: phone, scene: 'register');
    if (!mounted) return;
    if (expiresIn == null) {
      _showMessage(
        ref.read(authControllerProvider).errorMessage ?? '验证码发送失败，请稍后重试',
      );
      return;
    }
    _showMessage('验证码已发送，$expiresIn 秒内有效');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _entryLocation() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return RoleNavigationConfig.tenant.entryLocation;
    return RoleNavigationConfig.entryLocationForSession(
      user.role,
      ref.read(appModeProvider),
    );
  }
}

class _RegisterFormPanel extends StatelessWidget {
  const _RegisterFormPanel({
    required this.nicknameController,
    required this.phoneController,
    required this.codeController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.hasAgreed,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onAgreementChanged,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
    required this.onRegister,
    required this.onGetCode,
  });

  final TextEditingController nicknameController;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool hasAgreed;
  final bool showPassword;
  final bool showConfirmPassword;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onConfirmPasswordVisibilityChanged;
  final VoidCallback onRegister;
  final VoidCallback onGetCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: nicknameController,
                hintText: '昵称',
                icon: Icons.person_outline,
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: phoneController,
                hintText: '手机号',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: codeController,
                hintText: '验证码',
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                suffix: AuthCodeButton(onPressed: onGetCode),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: passwordController,
                hintText: '设置密码',
                icon: Icons.lock_outline,
                obscureText: !showPassword,
                inputFormatters: [LengthLimitingTextInputFormatter(32)],
                suffix: AuthVisibilityButton(
                  isVisible: showPassword,
                  onPressed: onPasswordVisibilityChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: confirmPasswordController,
                hintText: '确认密码',
                icon: Icons.lock_outline,
                obscureText: !showConfirmPassword,
                inputFormatters: [LengthLimitingTextInputFormatter(32)],
                suffix: AuthVisibilityButton(
                  isVisible: showConfirmPassword,
                  onPressed: onConfirmPasswordVisibilityChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(label: '注册', onPressed: onRegister),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '返回登录',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthAgreementRow(
                isChecked: hasAgreed,
                prefixText: '我已阅读并同意',
                onChanged: onAgreementChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
