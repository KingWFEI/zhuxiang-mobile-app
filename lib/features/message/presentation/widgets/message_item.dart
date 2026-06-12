import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../mock/message_mock.dart';

class MessageItem extends StatelessWidget {
  const MessageItem({required this.message, super.key});

  final MockMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: message.color.withValues(alpha: 0.12),
            child: Icon(message.icon, color: message.color, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message.content,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(message.time, style: AppTextStyles.bodyMedium),
              if (message.unreadCount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.error,
                  child: Text(
                    '${message.unreadCount}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
