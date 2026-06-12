import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../providers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _credentialController = TextEditingController();
  bool _hasAgreed = false;
  bool _isPasswordVisible = false;
  LoginMode _loginMode = LoginMode.code;

  @override
  void dispose() {
    _phoneController.dispose();
    _credentialController.dispose();
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
                const AuthPageHeader(title: '欢迎登录', subtitle: '租房、入住、开锁，一站式完成'),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: _LoginFormPanel(
                    phoneController: _phoneController,
                    credentialController: _credentialController,
                    loginMode: _loginMode,
                    isPasswordVisible: _isPasswordVisible,
                    hasAgreed: _hasAgreed,
                    onAgreementChanged: (value) {
                      setState(() => _hasAgreed = value);
                    },
                    onLogin: _handleLogin,
                    onGetCode: _handleGetCode,
                    onToggleLoginMode: _toggleLoginMode,
                    onTogglePasswordVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final credential = _credentialController.text.trim();

    if (phone.isEmpty) {
      _showMessage('请输入手机号');
      return;
    }
    if (phone.length != 11) {
      _showMessage('请输入正确的手机号');
      return;
    }
    if (credential.isEmpty) {
      _showMessage(_loginMode == LoginMode.code ? '请输入验证码' : '请输入密码');
      return;
    }
    if (_loginMode == LoginMode.code && credential.length != 6) {
      _showMessage('请输入6位验证码');
      return;
    }
    if (!_hasAgreed) {
      _showMessage('请先阅读并同意用户协议和隐私政策');
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    final success = switch (_loginMode) {
      LoginMode.code => await controller.loginWithCode(
        phone: phone,
        code: credential,
      ),
      LoginMode.password => await controller.loginWithPassword(
        phone: phone,
        password: credential,
      ),
    };
    if (!mounted) return;
    if (success) {
      context.goNamed(RouteNames.main);
      return;
    }

    final message =
        ref.read(authControllerProvider).errorMessage ?? '登录失败，请稍后重试';
    _showMessage(message);
  }

  void _handleGetCode() {
    if (_phoneController.text.trim().isEmpty) {
      _showMessage('请输入手机号');
      return;
    }
    _showMessage('当前 mock 验证码：246810');
  }

  void _toggleLoginMode() {
    setState(() {
      _loginMode = _loginMode == LoginMode.code
          ? LoginMode.password
          : LoginMode.code;
      _credentialController.clear();
      _isPasswordVisible = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum LoginMode { code, password }

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.phoneController,
    required this.credentialController,
    required this.loginMode,
    required this.isPasswordVisible,
    required this.hasAgreed,
    required this.onAgreementChanged,
    required this.onLogin,
    required this.onGetCode,
    required this.onToggleLoginMode,
    required this.onTogglePasswordVisibility,
  });

  final TextEditingController phoneController;
  final TextEditingController credentialController;
  final LoginMode loginMode;
  final bool isPasswordVisible;
  final bool hasAgreed;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onLogin;
  final VoidCallback onGetCode;
  final VoidCallback onToggleLoginMode;
  final VoidCallback onTogglePasswordVisibility;

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
          const SizedBox(height: AppSpacing.lg),
          AuthTextField(
            key: ValueKey(loginMode),
            controller: credentialController,
            hintText: loginMode == LoginMode.code ? '验证码' : '密码',
            icon: loginMode == LoginMode.code
                ? Icons.verified_user_outlined
                : Icons.lock_outline_rounded,
            keyboardType: loginMode == LoginMode.code
                ? TextInputType.number
                : TextInputType.visiblePassword,
            obscureText: loginMode == LoginMode.password && !isPasswordVisible,
            inputFormatters: loginMode == LoginMode.code
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ]
                : [LengthLimitingTextInputFormatter(32)],
            suffix: loginMode == LoginMode.code
                ? AuthCodeButton(onPressed: onGetCode)
                : AuthVisibilityButton(
                    isVisible: isPasswordVisible,
                    onPressed: onTogglePasswordVisibility,
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPrimaryButton(label: '登录', onPressed: onLogin),
          const SizedBox(height: AppSpacing.lg),
          AuthPrimaryButton(
            label: loginMode == LoginMode.code ? '密码登录' : '验证码登录',
            onPressed: onToggleLoginMode,
            isOutlined: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => context.goNamed(RouteNames.main),
            child: Text(
              '游客浏览',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '没有账号？',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.register),
                child: Text(
                  '立即注册',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AuthAgreementRow(isChecked: hasAgreed, onChanged: onAgreementChanged),
        ],
      ),
    );
  }
}
