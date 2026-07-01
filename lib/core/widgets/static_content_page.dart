import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// 展示本地静态文本内容的通用页面。
///
/// 用于用户协议、隐私政策等纯文本展示场景。
class StaticContentPage extends StatelessWidget {
  const StaticContentPage({
    required this.title,
    required this.content,
    super.key,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: SelectableText(
          content,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.8),
        ),
      ),
    );
  }
}
