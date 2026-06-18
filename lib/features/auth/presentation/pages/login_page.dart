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
                  offset: const Offset(0, -16),
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
                    onGuestBrowse: _handleGuestBrowse,
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

  Future<void> _handleGetCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      _showMessage('请输入正确的手机号');
      return;
    }

    final expiresIn = await ref
        .read(authControllerProvider.notifier)
        .sendSmsCode(phone: phone, scene: 'login');
    if (!mounted) return;
    if (expiresIn == null) {
      _showMessage(
        ref.read(authControllerProvider).errorMessage ?? '验证码发送失败，请稍后重试',
      );
      return;
    }
    _showMessage('验证码已发送，$expiresIn 秒内有效');
  }

  Future<void> _handleGuestBrowse() async {
    await ref.read(authControllerProvider.notifier).enterGuestMode();
    if (!mounted) return;
    context.goNamed(RouteNames.main);
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
    required this.onGuestBrowse,
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
  final VoidCallback onGuestBrowse;
  final VoidCallback onGetCode;
  final VoidCallback onToggleLoginMode;
  final VoidCallback onTogglePasswordVisibility;

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
                key: ValueKey(loginMode),
                controller: credentialController,
                hintText: loginMode == LoginMode.code ? '验证码' : '密码',
                icon: loginMode == LoginMode.code
                    ? Icons.verified_user_outlined
                    : Icons.lock_outline_rounded,
                keyboardType: loginMode == LoginMode.code
                    ? TextInputType.number
                    : TextInputType.visiblePassword,
                obscureText:
                    loginMode == LoginMode.password && !isPasswordVisible,
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
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(label: '登录', onPressed: onLogin),
              const SizedBox(height: AppSpacing.sm),
              _LoginSecondaryActions(
                loginMode: loginMode,
                onToggleLoginMode: onToggleLoginMode,
                onGuestBrowse: onGuestBrowse,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '没有账号？',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.goNamed(RouteNames.register),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '立即注册',
                      style: AppTextStyles.bodySmall.copyWith(
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
                onChanged: onAgreementChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginSecondaryActions extends StatelessWidget {
  const _LoginSecondaryActions({
    required this.loginMode,
    required this.onToggleLoginMode,
    required this.onGuestBrowse,
  });

  final LoginMode loginMode;
  final VoidCallback onToggleLoginMode;
  final VoidCallback onGuestBrowse;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onToggleLoginMode,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              loginMode == LoginMode.code ? '密码登录' : '验证码登录',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Container(width: 1, height: 14, color: AppColors.border),
        Expanded(
          child: TextButton(
            onPressed: onGuestBrowse,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '游客浏览',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
