import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

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
      height: 56,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        style: AppTextStyles.bodyLarge.copyWith(fontSize: 18),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textMuted,
            fontSize: 20,
          ),
          prefixIcon: Icon(icon, color: AppColors.iconMuted, size: 28),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 0),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
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

class AuthCodeButton extends StatelessWidget {
  const AuthCodeButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 1, height: 24, color: AppColors.border),
          TextButton(
            onPressed: onPressed,
            child: Text(
              '获取验证码',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
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
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.iconMuted,
      ),
    );
  }
}
