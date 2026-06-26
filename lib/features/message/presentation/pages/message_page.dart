import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../mock/message_mock.dart';
import '../widgets/message_item.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  static const _tabs = ['全部', '系统通知', '租约消息', '开锁通知'];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected = _tabs[_selectedIndex];
    final messages = selected == '全部'
        ? messageMock
        : messageMock.where((m) => m.category == selected).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('消息中心', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tabs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, index) {
                        final active = index == _selectedIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: active ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _tabs[index],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: active ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.sm,
                  AppSpacing.pageHorizontal,
                  120,
                ),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) => MessageItem(message: messages[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
