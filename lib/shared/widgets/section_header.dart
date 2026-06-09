import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionText,
    this.onActionPressed,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionText != null) ...[
          const SizedBox(width: AppSpacing.md),
          TextButton(onPressed: onActionPressed, child: Text(actionText!)),
        ],
      ],
    );
  }
}
