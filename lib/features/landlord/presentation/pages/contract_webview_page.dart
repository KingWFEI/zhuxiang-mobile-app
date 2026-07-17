import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_colors.dart';

class LandlordContractWebviewPage extends StatefulWidget {
  const LandlordContractWebviewPage({required this.signUrl, super.key});
  final String signUrl;

  @override
  State<LandlordContractWebviewPage> createState() =>
      _LandlordContractWebviewPageState();
}

class _LandlordContractWebviewPageState
    extends State<LandlordContractWebviewPage> {
  late final WebViewController _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) =>
              mounted ? setState(() => _progress = value) : null,
        ),
      )
      ..loadRequest(Uri.parse(widget.signUrl));
  }

  Future<void> _close() async {
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
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('合同签署'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
