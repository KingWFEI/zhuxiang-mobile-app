import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.cityName});

  final String? cityName;

  @override
  Widget build(BuildContext context) {
    final hasCity = cityName != null && cityName!.isNotEmpty;
    return Row(
      children: [
        Image.asset(
          'assets/zhuxiang_logo.png',
          width: 24,
          height: 20,
          fit: BoxFit.fill,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          hasCity ? '住享 · $cityName' : '住享',
          style: AppTextStyles.logoTitle,
        ),
      ],
    );
  }
}
