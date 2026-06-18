import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class HomeServiceEntry extends StatelessWidget {
  const HomeServiceEntry({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          // horizontal: AppSpacing.sm,
          vertical: AppSpacing.lg,
        ),
        // decoration: BoxDecoration(
        //   color: AppColors.surface,
        //   borderRadius: BorderRadius.circular(AppRadius.lg),
        //   border: Border.all(color: AppColors.border),
        // ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
