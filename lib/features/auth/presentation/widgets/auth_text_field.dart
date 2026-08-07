import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/auth_models.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    super.key,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 38,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class AuthCodeButton extends StatefulWidget {
  const AuthCodeButton({
    required this.onPressed,
    this.retryAfterOnFailure,
    this.now,
    super.key,
  });

  final Future<SmsCodeResult?> Function() onPressed;
  final int? Function()? retryAfterOnFailure;
  @visibleForTesting
  final DateTime Function()? now;

  @override
  State<AuthCodeButton> createState() => _AuthCodeButtonState();
}

class _AuthCodeButtonState extends State<AuthCodeButton>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _availableAt;
  int _remainingSeconds = 0;
  bool _isRequesting = false;
  bool _hasRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncRemaining();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_isRequesting || _remainingSeconds > 0) return;
    setState(() => _isRequesting = true);
    try {
      final result = await widget.onPressed();
      if (!mounted) return;
      final retryAfter =
          result?.retryAfter ?? widget.retryAfterOnFailure?.call() ?? 0;
      if (retryAfter > 0) {
        _startCountdown(retryAfter);
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _startCountdown(int seconds) {
    _hasRequested = true;
    _availableAt = _now().add(Duration(seconds: seconds));
    _timer?.cancel();
    _syncRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemaining();
    });
  }

  void _syncRemaining() {
    final availableAt = _availableAt;
    if (availableAt == null || !mounted) return;
    final milliseconds = availableAt.difference(_now()).inMilliseconds;
    final remaining = milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
    if (remaining == 0) {
      _timer?.cancel();
      _timer = null;
      _availableAt = null;
    }
    if (_remainingSeconds != remaining) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  String get _label {
    if (_isRequesting) return '发送中...';
    if (_remainingSeconds > 0) return '$_remainingSeconds秒后重试';
    return _hasRequested ? '重新获取' : '获取验证码';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !_isRequesting && _remainingSeconds == 0;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 1, height: 18, color: AppColors.border),
          TextButton(
            onPressed: enabled ? _requestCode : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _label,
              style: AppTextStyles.bodySmall.copyWith(
                color: enabled ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthVisibilityButton extends StatelessWidget {
  const AuthVisibilityButton({
    required this.isVisible,
    required this.onPressed,
    super.key,
  });

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.iconMuted,
      ),
    );
  }
}
