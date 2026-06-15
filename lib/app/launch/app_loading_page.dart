import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppLoadingPage extends ConsumerStatefulWidget {
  const AppLoadingPage({super.key});

  static const loadingDuration = Duration(milliseconds: 1400);

  @override
  ConsumerState<AppLoadingPage> createState() => _AppLoadingPageState();
}

class _AppLoadingPageState extends ConsumerState<AppLoadingPage> {
  Timer? _minimumLoadingTimer;
  bool _minimumLoadingFinished = false;
  bool _sessionRestoreFinished = false;

  @override
  void initState() {
    super.initState();
    _minimumLoadingTimer = Timer(AppLoadingPage.loadingDuration, () {
      _minimumLoadingFinished = true;
      _navigateWhenReady();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) return;
    _sessionRestoreFinished = true;
    _navigateWhenReady();
  }

  void _navigateWhenReady() {
    if (!mounted || !_minimumLoadingFinished || !_sessionRestoreFinished) {
      return;
    }
    final authState = ref.read(authControllerProvider);
    context.goNamed(
      authState.isLoggedIn || authState.isGuest
          ? RouteNames.main
          : RouteNames.login,
    );
  }

  @override
  void dispose() {
    _minimumLoadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = (constraints.maxHeight * 0.34)
                .clamp(220.0, 300.0)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  _LoadingPlaceholderImage(height: imageHeight),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    '住享',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '把租住安排得更简单',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const _LoadingStatus(),
                  const Spacer(),
                  Text(
                    '正在进入应用',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingPlaceholderImage extends StatelessWidget {
  const _LoadingPlaceholderImage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '加载页占位图',
      image: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF4FF), Color(0xFFF1FBF9)],
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 28,
              right: 28,
              bottom: 24,
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 32,
              left: 32,
              child: _ImageTile(
                icon: Icons.apartment,
                color: AppColors.primary,
                size: height * 0.32,
              ),
            ),
            Positioned(
              top: 52,
              right: 36,
              child: _ImageTile(
                icon: Icons.key_outlined,
                color: AppColors.secondary,
                size: height * 0.24,
              ),
            ),
            Positioned(
              left: 44,
              right: 44,
              bottom: 46,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.home, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FractionallySizedBox(
                          widthFactor: 0.64,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD3E8FA),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: const LinearProgressIndicator(
            value: 0.72,
            minHeight: 6,
            backgroundColor: Color(0xFFE5E7EB),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('正在加载房源与租约信息', style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }
}
