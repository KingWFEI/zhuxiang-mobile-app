import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/app_message.dart';

class MessageDetailPage extends StatelessWidget {
  const MessageDetailPage({required this.message, super.key});

  final AppMessage message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('消息详情'),
        leading: IconButton(
          icon: AppIcon.iconBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              48,
            ),
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title.isEmpty ? '消息通知' : message.title,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (message.createdAt != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _formatDateTime(message.createdAt!),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      message.content.isEmpty ? '暂无消息内容' : message.content,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime time) {
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
