import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/network/api_result.dart';
import '../../data/models/immersive_tour.dart';
import '../../data/providers/house_providers.dart';

class ImmersiveTourPage extends ConsumerWidget {
  const ImmersiveTourPage({required this.houseId, super.key});

  final String houseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourAsync = ref.watch(immersiveTourProvider(houseId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: tourAsync.when(
        data: (result) {
          if (result is ApiFailure<ImmersiveTour>) {
            return _TourErrorView(
              message: result.message,
              onRetry: () => ref.invalidate(immersiveTourProvider(houseId)),
            );
          }

          if (result is! ApiSuccess<ImmersiveTour>) {
            return _TourErrorView(
              message: '沉浸式看房加载失败',
              onRetry: () => ref.invalidate(immersiveTourProvider(houseId)),
            );
          }

          final tour = result.data;
          if (tour.scenes.isEmpty) {
            return _TourErrorView(
              message: '该房源暂无可展示的看房场景',
              onRetry: () => ref.invalidate(immersiveTourProvider(houseId)),
            );
          }

          if (!_isWebViewSupportedPlatform) {
            return _TourErrorView(
              message: '当前调试平台暂不支持 WebView 全景看房，请在 Android、iOS 或 macOS 设备上运行验证',
              onRetry: () => ref.invalidate(immersiveTourProvider(houseId)),
            );
          }

          return _ImmersiveTourWebView(tour: tour);
        },
        error: (error, stackTrace) => _TourErrorView(
          message: '沉浸式看房加载异常：$error',
          onRetry: () => ref.invalidate(immersiveTourProvider(houseId)),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}

bool get _isWebViewSupportedPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    _ => false,
  };
}

class _ImmersiveTourWebView extends StatefulWidget {
  const _ImmersiveTourWebView({required this.tour});

  final ImmersiveTour tour;

  @override
  State<_ImmersiveTourWebView> createState() => _ImmersiveTourWebViewState();
}

class _ImmersiveTourWebViewState extends State<_ImmersiveTourWebView> {
  late final WebViewController _controller;
  var _isPageReady = false;
  var _hasInjectedTour = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _isPageReady = true;
            _injectTour();
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _loadError = '沉浸式看房页面加载失败：${error.description}';
            });
          },
        ),
      )
      ..loadFlutterAsset('assets/immersive_tour_viewer.html');
  }

  @override
  void didUpdateWidget(covariant _ImmersiveTourWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tour.tourId != widget.tour.tourId) {
      _hasInjectedTour = false;
      _injectTour();
    }
  }

  Future<void> _injectTour() async {
    if (!_isPageReady || _hasInjectedTour) return;

    _debugLogTourHotspots(widget.tour);
    final payload = jsonEncode(widget.tour.toJson());
    try {
      await _controller.runJavaScript('window.renderTour($payload);');
      if (mounted) {
        setState(() {
          _hasInjectedTour = true;
          _loadError = null;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loadError = '沉浸式看房渲染失败：$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ),
        if (_loadError != null)
          _WebViewErrorOverlay(
            message: _loadError!,
            onRetry: () {
              setState(() {
                _loadError = null;
                _hasInjectedTour = false;
              });
              _controller.reload();
            },
          )
        else if (!_hasInjectedTour)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }
}

void _debugLogTourHotspots(ImmersiveTour tour) {
  if (!kDebugMode) return;
  for (final scene in tour.scenes) {
    debugPrint(
      '[ImmersiveTour] scene=${scene.sceneId} sceneHotspots=${scene.hotspots.length}',
    );
    for (final image in scene.images) {
      debugPrint(
        '[ImmersiveTour] image=${image.imageId} hotspots=${image.hotspots.length}',
      );
    }
  }
}

class _WebViewErrorOverlay extends StatelessWidget {
  const _WebViewErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourErrorView extends StatelessWidget {
  const _TourErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.view_in_ar_outlined,
              color: Colors.white54,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
