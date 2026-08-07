import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icon.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            _StaticContentHeader(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: SelectableText(
                  content,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticContentHeader extends StatelessWidget {
  const _StaticContentHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StaticContentBackButton(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(title, style: AppTextStyles.normalPageTitle),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

class _StaticContentBackButton extends StatelessWidget {
  const _StaticContentBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.goNamed(RouteNames.home);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: AppIcon.iconBack,
      ),
    );
  }
}
