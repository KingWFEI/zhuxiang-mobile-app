import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class RentalApplicationPage extends StatelessWidget {
  const RentalApplicationPage({required this.houseId, super.key});

  final String houseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        title: const Text('租住申请'),
        centerTitle: true,
        backgroundColor: AppColors.authBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home_work_outlined,
                    color: AppColors.primary,
                    size: 42,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('请从房源详情页发起申请', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '新的租住流程会先弹出确认租住窗口，再创建租住订单。',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.goNamed(
                      RouteNames.houseDetail,
                      pathParameters: {'houseId': houseId},
                    ),
                    child: const Text('返回房源详情'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
