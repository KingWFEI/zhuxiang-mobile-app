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
  final _codeController = TextEditingController();
  bool _hasAgreed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
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
                    codeController: _codeController,
                    hasAgreed: _hasAgreed,
                    onAgreementChanged: (value) {
                      setState(() => _hasAgreed = value);
                    },
                    onLogin: _handleLogin,
                    onGetCode: _handleGetCode,
                    onPasswordLogin: _handlePasswordLogin,
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
    final code = _codeController.text.trim();

    if (phone.isEmpty) {
      _showMessage('请输入手机号');
      return;
    }
    if (code.isEmpty) {
      _showMessage('请输入验证码');
      return;
    }
    if (!_hasAgreed) {
      _showMessage('请先阅读并同意用户协议和隐私政策');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(phone: phone, code: code);
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
    _showMessage('验证码功能暂未接入接口');
  }

  void _handlePasswordLogin() {
    _showMessage('当前 mock 账号使用验证码登录：13800138000 / 123456');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.phoneController,
    required this.codeController,
    required this.hasAgreed,
    required this.onAgreementChanged,
    required this.onLogin,
    required this.onGetCode,
    required this.onPasswordLogin,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final bool hasAgreed;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onLogin;
  final VoidCallback onGetCode;
  final VoidCallback onPasswordLogin;

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
          const SizedBox(height: AppSpacing.xl),
          AuthPrimaryButton(label: '登录', onPressed: onLogin),
          const SizedBox(height: AppSpacing.lg),
          AuthPrimaryButton(
            label: '密码登录',
            onPressed: onPasswordLogin,
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
