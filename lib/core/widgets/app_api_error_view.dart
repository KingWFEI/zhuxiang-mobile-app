import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../app/theme/app_spacing.dart';
import '../network/api_exception.dart';

/// 用于展示接口请求失败时后端返回的 message。
class AppApiErrorView extends StatelessWidget {
  const AppApiErrorView({
    this.message,
    this.error,
    this.title,
    this.actionLabel,
    this.onRetry,
    super.key,
  });

  final String? message;
  final Object? error;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final errorMessage = message?.trim();
    final apiMessage = error is ApiException
        ? (error as ApiException).message.trim()
        : null;
    final displayMessage = errorMessage?.isNotEmpty == true
        ? errorMessage
        : apiMessage?.isNotEmpty == true
        ? apiMessage
        : error?.toString() ?? title;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCloudOff,
              size: 34,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayMessage?.isNotEmpty == true
                  ? displayMessage!
                  : '接口请求失败，请稍后重试',
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(actionLabel ?? '重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
