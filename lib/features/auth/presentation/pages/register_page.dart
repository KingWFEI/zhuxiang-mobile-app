import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/auth_agreement_row.dart';
import '../widgets/auth_page_header.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hasAgreed = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
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
                  offset: const Offset(0, -22),
                  child: _RegisterFormPanel(
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

  void _handleRegister() {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (phone.isEmpty) {
      _showMessage('请输入手机号');
      return;
    }
    if (code.isEmpty) {
      _showMessage('请输入验证码');
      return;
    }
    if (password.isEmpty) {
      _showMessage('请设置密码');
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

    _showMessage('注册功能暂未接入接口');
  }

  void _handleGetCode() {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('请输入手机号');
      return;
    }
    _showMessage('验证码功能暂未接入接口');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RegisterFormPanel extends StatelessWidget {
  const _RegisterFormPanel({
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            suffix: AuthVisibilityButton(
              isVisible: showConfirmPassword,
              onPressed: onConfirmPasswordVisibilityChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthPrimaryButton(label: '注册', onPressed: onRegister),
          const SizedBox(height: AppSpacing.md),
          AuthPrimaryButton(
            label: '返回登录',
            onPressed: () => context.goNamed(RouteNames.login),
            isOutlined: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '已有账号？',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.login),
                child: Text(
                  '立即登录',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AuthAgreementRow(
            isChecked: hasAgreed,
            prefixText: '我已阅读并同意',
            onChanged: onAgreementChanged,
          ),
        ],
      ),
    );
  }
}
