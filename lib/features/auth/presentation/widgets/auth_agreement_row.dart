import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class AuthAgreementRow extends StatelessWidget {
  const AuthAgreementRow({
    required this.isChecked,
    required this.onChanged,
    super.key,
    this.prefixText = '登录即表示同意',
  });

  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final String prefixText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!isChecked),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              isChecked
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked_outlined,
              color: isChecked ? AppColors.primary : AppColors.inputBorder,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text.rich(
            TextSpan(
              text: prefixText,
              style: AppTextStyles.bodySmall,
              children: [
                TextSpan(
                  text: '《用户协议》',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showUnavailable(context),
                ),
                TextSpan(text: '  ', style: AppTextStyles.bodySmall),
                TextSpan(
                  text: '《隐私政策》',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showUnavailable(context),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('协议内容暂未接入')));
  }
}
