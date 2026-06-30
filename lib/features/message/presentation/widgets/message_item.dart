import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/app_message.dart';

class MessageItem extends StatelessWidget {
  const MessageItem({
    required this.message,
    required this.onTap,
    required this.onDelete,
    required this.onDeleted,
    super.key,
  });

  final AppMessage message;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ObjectKey(message),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      onDismissed: (_) => onDeleted(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(height: AppSpacing.xs),
            Text('删除', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: message.isRead
                    ? AppColors.border
                    : AppColors.primary.withValues(alpha: 0.18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageIcon(message: message),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!message.isRead) ...[
                            const CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              message.title.isEmpty ? '消息通知' : message.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 15,
                                fontWeight: message.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _formatTime(message.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message.content.isEmpty ? '暂无消息内容' : message.content,
                        style: AppTextStyles.bodySmall.copyWith(height: 1.45),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageIcon extends StatelessWidget {
  const _MessageIcon({required this.message});

  final AppMessage message;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(message.category);
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(_messageIcon(message), color: color, size: 20),
    );
  }
}

IconData _messageIcon(AppMessage message) {
  final iconKey = message.iconKey?.toLowerCase();
  if (iconKey != null) {
    if (iconKey.contains('contract') || iconKey.contains('lease')) {
      return Icons.description_outlined;
    }
    if (iconKey.contains('bill') || iconKey.contains('wallet')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (iconKey.contains('lock') || iconKey.contains('door')) {
      return Icons.lock_open_outlined;
    }
    if (iconKey.contains('repair') || iconKey.contains('build')) {
      return Icons.build_outlined;
    }
    if (iconKey.contains('appointment') || iconKey.contains('event')) {
      return Icons.event_available_outlined;
    }
  }
  return switch (message.category) {
    MessageCategory.appointment => Icons.event_available_outlined,
    MessageCategory.lease => Icons.description_outlined,
    MessageCategory.bill => Icons.account_balance_wallet_outlined,
    MessageCategory.repair => Icons.build_outlined,
    MessageCategory.lock => Icons.lock_open_outlined,
    MessageCategory.system || null => Icons.notifications_none_rounded,
  };
}

Color _categoryColor(MessageCategory? category) {
  return switch (category) {
    MessageCategory.appointment => AppColors.secondary,
    MessageCategory.lease => AppColors.primary,
    MessageCategory.bill => AppColors.warning,
    MessageCategory.repair => const Color(0xFF7C4DFF),
    MessageCategory.lock => const Color(0xFF00A3A3),
    MessageCategory.system || null => AppColors.primaryDark,
  };
}

String _formatTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(time.year, time.month, time.day);
  final clock =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (date == today) return '今天 $clock';
  if (date == today.subtract(const Duration(days: 1))) return '昨天 $clock';
  return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} $clock';
}
