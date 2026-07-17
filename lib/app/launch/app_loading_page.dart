import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/user_location_provider.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../router/app_mode_controller.dart';
import '../router/role_navigation_config.dart';
import '../router/route_paths.dart';

class AppLoadingPage extends ConsumerStatefulWidget {
  const AppLoadingPage({super.key});

  static const loadingDuration = Duration(milliseconds: 1400);
  static bool debugStayOnPage = false;

  @override
  ConsumerState<AppLoadingPage> createState() => _AppLoadingPageState();
}

class _AppLoadingPageState extends ConsumerState<AppLoadingPage>
    with SingleTickerProviderStateMixin {
  Timer? _minimumLoadingTimer;
  late final AnimationController _progressController;
  bool _minimumLoadingFinished = false;
  bool _sessionRestoreFinished = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: AppLoadingPage.loadingDuration,
    )..animateTo(0.55, curve: Curves.easeOutCubic);

    _minimumLoadingTimer = Timer(AppLoadingPage.loadingDuration, () {
      _minimumLoadingFinished = true;
      _navigateWhenReady();
    });
    // 启动阶段并行加载：会话恢复 + 后台定位
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
      ref.read(userLocationProvider.notifier).fetch();
    });
  }

  Future<void> _restoreSession() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) return;
    _sessionRestoreFinished = true;
    _navigateWhenReady();
  }

  void _navigateWhenReady() {
    if (AppLoadingPage.debugStayOnPage) return;
    if (!mounted ||
        !_minimumLoadingFinished ||
        !_sessionRestoreFinished ||
        _navigated) {
      return;
    }
    _navigated = true;
    _minimumLoadingTimer?.cancel();

    final authState = ref.read(authControllerProvider);
    final target = authState.isGuest
        ? RoleNavigationConfig.tenant.entryLocation
        : authState.user == null
        ? RoutePaths.login
        : RoleNavigationConfig.entryLocationForSession(
            authState.user!.role,
            ref.read(appModeProvider),
          );

    GoRouter.of(context).go(target);
  }

  @override
  void dispose() {
    _minimumLoadingTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF8FAFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final contentWidth = width.clamp(320.0, 520.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  label: '住享社区建筑背景',
                  image: true,
                  child: Image.asset(
                    'assets/app_load_back.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  top: height * 0.165,
                  left: 0,
                  right: 0,
                  child: _BrandLockup(contentWidth: contentWidth),
                ),
                Positioned(
                  top: height * 0.290,
                  left: 20,
                  right: 20,
                  child: Text(
                    '让每一次归家，都心中有数',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: const Color(0xFF6E84A5),
                      fontSize: (contentWidth * 0.044).clamp(14.0, 20.0),
                      fontWeight: FontWeight.w400,
                      letterSpacing: (contentWidth * 0.012).clamp(3.5, 5.5),
                      height: 1.2,
                    ),
                  ),
                ),
                Positioned(
                  left: width * 0.16,
                  right: width * 0.16,
                  bottom: MediaQuery.paddingOf(context).bottom + height * 0.082,
                  child: _LoadingProgress(animation: _progressController),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.contentWidth});

  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final logoSize = (contentWidth * 0.18).clamp(62.0, 88.0);
    final titleSize = (contentWidth * 0.105).clamp(36.0, 50.0);

    return Semantics(
      label: '住享',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/zhuxiang_logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(width: contentWidth * 0.045),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF168BFF), Color(0xFF315FEA)],
              ).createShader(bounds),
              child: Text(
                '住享',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '正在加载',
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: animation.value,
              minHeight: 3,
              backgroundColor: const Color(0xFFDCE6F7),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4A8BFF)),
            ),
          );
        },
      ),
    );
  }
}
