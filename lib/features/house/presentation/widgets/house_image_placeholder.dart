import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';

class HouseImagePlaceholder extends StatelessWidget {
  const HouseImagePlaceholder({super.key, this.height, this.borderRadius});

  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3E7D8), Color(0xFFEAF4FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.weekend_outlined,
              color: AppColors.textSecondary,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }
}
