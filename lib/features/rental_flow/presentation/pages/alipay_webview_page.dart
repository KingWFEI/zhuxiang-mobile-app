import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/rental_flow_providers.dart';

class AlipayWebViewPage extends ConsumerStatefulWidget {
  const AlipayWebViewPage({
    required this.paymentUrl,
    required this.orderId,
    required this.paymentNo,
    super.key,
  });

  final String paymentUrl;
  final String orderId;
  final String paymentNo;

  @override
  ConsumerState<AlipayWebViewPage> createState() => _AlipayWebViewPageState();
}

class _AlipayWebViewPageState extends ConsumerState<AlipayWebViewPage> {
  late final WebViewController _controller;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<bool> _checkPayment() async {
    try {
      final service = ref.read(rentalFlowServiceProvider);
      return await service.confirmAlipayPayment(widget.paymentNo);
    } on Object catch (_) {
      return false;
    }
  }

  /// 用户主动点关闭按钮 / 手势退出
  Future<void> _exit() async {
    if (_checking) return;
    setState(() => _checking = true);

    final paid = await _checkPayment();

    if (!mounted) return;

    if (paid) {
      ref.invalidate(myRentOrdersProvider);
      Navigator.pop(context, true);
      return;
    }

    setState(() => _checking = false);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('支付未完成'),
        content: const Text('暂未查询到支付记录，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续支付'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('确定离开', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _checking = true);
      final second = await _checkPayment();
      if (!mounted) return;
      if (second) ref.invalidate(myRentOrdersProvider);
      Navigator.pop(context, second);
    }
  }

  /// 系统返回键：先让 WebView 处理内部回退，WebView 无法回退时才触发退出检查
  Future<bool> _onSystemBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // 不退出页面，WebView 内部回退
    }
    _exit();
    return false; // 永远不由系统直接 pop
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onSystemBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_checking) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '正在确认支付结果…',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        // 顶端关闭按钮
        Container(
          height: 48,
          padding: const EdgeInsets.only(left: 4),
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exit,
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }
}
