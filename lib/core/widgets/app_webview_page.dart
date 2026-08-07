import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme/app_colors.dart';

/// App 内通用网页容器，用于实名认证、电子签署等业务页面。
class AppWebViewPage extends StatefulWidget {
  const AppWebViewPage({
    required this.title,
    required this.initialUrl,
    this.allowCamera = false,
    super.key,
  });

  final String title;
  final String initialUrl;
  final bool allowCamera;

  static bool supportsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  State<AppWebViewPage> createState() => _AppWebViewPageState();
}

class _AppWebViewPageState extends State<AppWebViewPage> {
  late final WebViewController _controller;
  var _progress = 0;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController(onPermissionRequest: _handlePermissionRequest)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (value) {
                if (mounted) setState(() => _progress = value);
              },
              onPageStarted: (_) {
                if (mounted && _pageError != null) {
                  setState(() => _pageError = null);
                }
              },
              onWebResourceError: (error) {
                if (error.isForMainFrame != true || !mounted) return;
                setState(() => _pageError = '页面加载失败，请检查网络后重试');
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handlePermissionRequest(
    WebViewPermissionRequest request,
  ) async {
    final requestsCameraOnly =
        request.types.isNotEmpty &&
        request.types.every(
          (type) => type == WebViewPermissionResourceType.camera,
        );
    if (!requestsCameraOnly) {
      await request.deny();
      return;
    }
    if (!widget.allowCamera) {
      await request.deny();
      return;
    }
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await request.grant();
    } else {
      await request.deny();
    }
  }

  Future<void> _handleSystemBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
            Expanded(
              child: _pageError == null
                  ? WebViewWidget(controller: _controller)
                  : _WebViewError(
                      message: _pageError!,
                      onRetry: () {
                        setState(() => _pageError = null);
                        _controller.reload();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebViewError extends StatelessWidget {
  const _WebViewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
