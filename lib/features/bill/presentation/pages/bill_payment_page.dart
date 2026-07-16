import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/providers/bill_providers.dart';

class BillPaymentPage extends ConsumerStatefulWidget {
  const BillPaymentPage({
    required this.paymentUrl,
    required this.billId,
    required this.paymentNo,
    super.key,
  });

  final String paymentUrl;
  final String billId;
  final String paymentNo;

  @override
  ConsumerState<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends ConsumerState<BillPaymentPage> {
  late final WebViewController _controller;
  Timer? _timer;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.paymentUrl));

    _timer = Timer(const Duration(seconds: 5), _check);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted || _confirmed) return;

    try {
      final service = ref.read(billServiceProvider);
      final ok = await service.confirmBillPayment(widget.paymentNo);
      if (ok && mounted) {
        _confirmed = true;
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) Navigator.pop(context, true);
        return;
      }
    } on Object catch (_) {}

    if (mounted && !_confirmed) {
      _timer = Timer(const Duration(seconds: 3), _check);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _confirmed ? _buildConfirmedView() : _buildWebView(),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.only(left: 4),
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onBackPressed,
          ),
        ),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    );
  }

  Widget _buildConfirmedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('支付成功', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '正在返回…',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  void _onBackPressed() {
    if (_confirmed) {
      Navigator.pop(context, true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认离开'),
        content: const Text('支付尚未完成，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续支付'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: Text(
              '确定离开',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
