import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class HouseLocationHeader extends StatelessWidget {
  const HouseLocationHeader({
    required this.city,
    required this.district,
    required this.onMapTap,
    super.key,
  });

  final String city;
  final String district;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _HeaderBuilding(),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.home_work,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('住享', style: AppTextStyles.logoTitle),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          city,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Transform.translate(
                          offset: const Offset(0, 1),
                          child: const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '当前定位 · $district',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBuilding extends StatelessWidget {
  const _HeaderBuilding();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: -20,
      width: 200,
      height: 100,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Image.asset(
            'assets/home_bk.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}
