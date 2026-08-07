import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final showAccountActions = authState.isLoggedIn && !authState.isGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4FF), Color(0xFFF5F9FF), Color(0xFFFBFDFF)],
            stops: [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _SettingsHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.md,
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                  ),
                  children: [
                    if (showAccountActions)
                      _SettingsItem(
                        icon: HugeIcons.strokeRoundedUser02,
                        label: '\u4fee\u6539\u8d26\u53f7\u4fe1\u606f',
                        subtitle:
                            '\u7f16\u8f91\u5934\u50cf\u3001\u6635\u79f0\u3001\u5bc6\u7801\u548c\u624b\u673a\u53f7',
                        onTap: () => context.pushNamed(RouteNames.profileEdit),
                      ),
                    if (showAccountActions)
                      const SizedBox(height: AppSpacing.xl),
                    const _SectionHeader(label: '\u5173\u4e8e'),
                    _SettingsItem(
                      icon: HugeIcons.strokeRoundedFile01,
                      label: '\u7528\u6237\u534f\u8bae',
                      onTap: () => context.pushNamed(RouteNames.userAgreement),
                    ),
                    _SettingsItem(
                      icon: HugeIcons.strokeRoundedShield01,
                      label: '\u9690\u79c1\u653f\u7b56',
                      onTap: () => context.pushNamed(RouteNames.privacyPolicy),
                    ),
                    const _VersionItem(version: '1.0.0'),
                  ],
                ),
              ),
              if (showAccountActions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sm,
                    AppSpacing.pageHorizontal,
                    AppSpacing.xxl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, ref),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedLogout01,
                        color: AppColors.error,
                        size: 19,
                      ),
                      label: const Text('\u9000\u51fa\u767b\u5f55'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.35),
                        ),
                        backgroundColor: AppColors.surface.withValues(
                          alpha: 0.58,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('\u9000\u51fa\u767b\u5f55'),
          content: const Text(
            '\u786e\u5b9a\u8981\u9000\u51fa\u5f53\u524d\u8d26\u53f7\u5417\uff1f',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('\u53d6\u6d88'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('\u9000\u51fa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

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
                child: _SettingsBackButton(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '\u8bbe\u7f6e',
                  style: AppTextStyles.normalPageTitle,
                ),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton();

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VersionItem extends StatelessWidget {
  const _VersionItem({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return _SettingsSurface(
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedFile01,
            color: AppColors.textPrimary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '\u5f53\u524d\u7248\u672c',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            version,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsSurface(
      onTap: onTap,
      child: Row(
        children: [
          HugeIcon(icon: icon, color: AppColors.primary, size: 23),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: AppColors.iconMuted,
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        elevation: 0,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: content,
              ),
      ),
    );
  }
}
