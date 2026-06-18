import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// 租房流程底部操作按钮。
class RentalActionBar extends StatelessWidget {
  const RentalActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
    this.secondaryLabel,
    this.onSecondary,
    this.isLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (secondaryLabel != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onPrimary,
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
