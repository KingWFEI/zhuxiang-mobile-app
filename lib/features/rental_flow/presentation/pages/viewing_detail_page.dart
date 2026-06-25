import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class ViewingDetailPage extends StatelessWidget {
  const ViewingDetailPage({required this.houseId, super.key});

  final String houseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        title: const Text('看房详情'),
        centerTitle: true,
        backgroundColor: AppColors.authBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            '房源 $houseId 的看房详情后续接入预约接口。',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ),
    );
  }
}
