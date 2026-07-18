import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class LandlordContractSignResultPage extends StatelessWidget {
  const LandlordContractSignResultPage({required this.completed, super.key});
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(completed ? '签署完成' : '签署成功'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 52,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                completed ? '合同签署完成' : '签署成功',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                completed ? '双方均已完成签署\n系统已生成租约' : '您已完成合同签署\n当前正在等待租客完成签署',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              if (completed) ...[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '可前往租约列表查看最新租约',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      context.goNamed(RouteNames.landlordWorkbench),
                  child: const Text('返回工作台'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
