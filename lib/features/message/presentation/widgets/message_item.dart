import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/app_message.dart';

class MessageItem extends StatelessWidget {
  const MessageItem({
    required this.message,
    required this.onTap,
    required this.onDelete,
    required this.onDeleted,
    this.showDivider = false,
    super.key,
  });

  final AppMessage message;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final VoidCallback onDeleted;
  final bool showDivider;

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
        color: AppColors.error,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: Colors.white,
            ),
            SizedBox(height: AppSpacing.xs),
            Text('删除', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageIcon(message: message),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 65,
                    padding: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      border: showDivider
                          ? const Border(
                              bottom: BorderSide(color: Color(0xFFF0F2F5)),
                            )
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.title.isEmpty ? '消息通知' : message.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF172236),
                                  fontSize: 16,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                message.content.isEmpty
                                    ? '暂无消息内容'
                                    : message.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8A94A5),
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 48,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(message.createdAt),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Color(0xFFA0A8B5),
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (!message.isRead) const _UnreadDot(),
                            ],
                          ),
                        ),
                      ],
                    ),
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
    final colors = _categoryGradient(message.category);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: HugeIcon(
              icon: _messageIcon(message),
              color: Colors.white,
              size: 26,
            ),
          ),
          if (!message.isRead)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5B55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF2478ED),
        shape: BoxShape.circle,
      ),
      child: const Text(
        '1',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<List<dynamic>> _messageIcon(AppMessage message) {
  final iconKey = message.iconKey?.toLowerCase();
  if (iconKey != null) {
    if (iconKey.contains('contract') || iconKey.contains('lease')) {
      return HugeIcons.strokeRoundedCalendar01;
    }
    if (iconKey.contains('bill') || iconKey.contains('wallet')) {
      return HugeIcons.strokeRoundedReceiptText;
    }
    if (iconKey.contains('lock') || iconKey.contains('door')) {
      return HugeIcons.strokeRoundedShield01;
    }
    if (iconKey.contains('repair') || iconKey.contains('build')) {
      return HugeIcons.strokeRoundedRepair;
    }
    if (iconKey.contains('appointment') || iconKey.contains('event')) {
      return HugeIcons.strokeRoundedMegaphone01;
    }
  }
  return switch (message.category) {
    MessageCategory.appointment => HugeIcons.strokeRoundedMegaphone01,
    MessageCategory.lease => HugeIcons.strokeRoundedCalendar01,
    MessageCategory.bill => HugeIcons.strokeRoundedReceiptText,
    MessageCategory.repair => HugeIcons.strokeRoundedRepair,
    MessageCategory.lock => HugeIcons.strokeRoundedShield01,
    MessageCategory.system || null => HugeIcons.strokeRoundedHome01,
  };
}

List<Color> _categoryGradient(MessageCategory? category) {
  return switch (category) {
    MessageCategory.appointment => const [Color(0xFF9E7BFF), Color(0xFF7454EF)],
    MessageCategory.lease => const [Color(0xFF5FD276), Color(0xFF33AE54)],
    MessageCategory.bill => const [Color(0xFFFFBE5C), Color(0xFFFF9D32)],
    MessageCategory.repair => const [Color(0xFF9B7CFA), Color(0xFF7458EC)],
    MessageCategory.lock => const [Color(0xFF5BB8FF), Color(0xFF318CEB)],
    MessageCategory.system ||
    null => const [Color(0xFF5CB4FF), Color(0xFF338CEB)],
  };
}

String _formatTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(time.year, time.month, time.day);
  final clock =
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  if (date == today) return clock;
  if (date == today.subtract(const Duration(days: 1))) return '昨天';
  return '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';
}
