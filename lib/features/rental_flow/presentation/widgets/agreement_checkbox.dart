import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class AgreementCheckbox extends StatelessWidget {
  const AgreementCheckbox({
    required this.value,
    required this.text,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final String text;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.primary,
            onChanged: (checked) => onChanged(checked ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(text, style: AppTextStyles.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}
