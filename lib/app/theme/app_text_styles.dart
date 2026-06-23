import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const logoTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );
  static const houseCardH1 = TextStyle(
    color: Color.fromARGB(255, 0, 0, 0),
    fontSize: 12,
    fontFamily: 'NotoSansSC',
  );
  static const houseCardH2 = TextStyle(
    fontSize: 8,
    color: Color.fromARGB(255, 65, 66, 66),
  );
  static const bottomTextStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
  static const titleLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const bodySmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const labelLarge = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  // 房屋详情页的专属标签样式
  static const housedetailtoolTitle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const housedetailtoolL1 = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const housedetailtoolL2 = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
