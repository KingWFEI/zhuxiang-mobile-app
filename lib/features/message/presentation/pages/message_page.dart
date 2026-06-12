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
        : messageMock.where((message) => message.category == selected).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: _MessageHeader(),
            ),
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.xl),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final selected = index == _selectedIndex;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(tab),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedIndex = index),
                    selectedColor: AppColors.primaryLight,
                    labelStyle: AppTextStyles.bodyLarge.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  120,
                ),
                itemCount: messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  return MessageItem(message: messages[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  const _MessageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.home_work, color: AppColors.primary, size: 34),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '住享',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primary,
            fontSize: 26,
          ),
        ),
        const Spacer(),
        Text('消息中心', style: AppTextStyles.titleLarge.copyWith(fontSize: 24)),
        const Spacer(),
        const Icon(Icons.cleaning_services_outlined, size: 28),
      ],
    );
  }
}
