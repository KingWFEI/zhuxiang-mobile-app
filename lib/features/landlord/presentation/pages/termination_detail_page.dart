import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_webview_page.dart';
import '../../data/models/landlord_contract.dart';
import '../../data/providers/landlord_providers.dart';

class LandlordTerminationDetailPage extends ConsumerStatefulWidget {
  const LandlordTerminationDetailPage({required this.applicationId, super.key});

  final String applicationId;

  @override
  ConsumerState<LandlordTerminationDetailPage> createState() =>
      _LandlordTerminationDetailPageState();
}

class _LandlordTerminationDetailPageState
    extends ConsumerState<LandlordTerminationDetailPage> {
  LandlordTerminationDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _signing = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(landlordContractServiceProvider)
          .getTerminationDetail(widget.applicationId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sign() async {
    if (_signing || _detail?.canSign != true) return;
    setState(() => _signing = true);
    try {
      var result = await ref
          .read(landlordContractServiceProvider)
          .signTermination(widget.applicationId);
      if (!mounted) return;
      if (_handleStatus(result)) return;
      if (!AppWebViewPage.supportsUrl(result.signUrl)) {
        throw const ApiException(
          type: ApiExceptionType.server,
          message: '未获取到有效的解约签署页面',
        );
      }
      await _openSigner(result);
      if (!mounted) return;

      // 首次可能是 e签宝授权，授权完成后重新获取真正的签署链接。
      if (result.isAuthorization) {
        result = await ref
            .read(landlordContractServiceProvider)
            .signTermination(widget.applicationId);
        if (!mounted) return;
        if (_handleStatus(result)) return;
        if (!result.isAuthorization &&
            AppWebViewPage.supportsUrl(result.signUrl)) {
          await _openSigner(result);
        } else if (result.isAuthorization) {
          AppToast.show(context, '授权尚未完成，请稍后再次点击签署');
          return;
        }
      }
      if (mounted) await _pollStatus();
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          error is ApiException ? error.message : '解约协议签署服务暂不可用',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  Future<void> _openSigner(RescissionSignResult result) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AppWebViewPage(
          title: result.isAuthorization ? '授权电子解约' : '签署解约协议',
          initialUrl: result.signUrl,
          allowCamera: true,
        ),
      ),
    );
  }

  Future<void> _pollStatus() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      for (var i = 0; i < 5; i++) {
        final result = await ref
            .read(landlordContractServiceProvider)
            .refreshTermination(widget.applicationId);
        if (!mounted || _handleStatus(result)) return;
        if (i < 4) await Future<void>.delayed(const Duration(seconds: 3));
      }
      if (mounted) AppToast.show(context, '暂未查询到签署结果，请稍后刷新');
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          error is ApiException ? error.message : '签署状态刷新失败',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _handleStatus(RescissionSignResult result) {
    if (!result.currentUserSigned && !result.completed) return false;
    ref.invalidate(landlordPendingSignCountsProvider);
    AppToast.show(
      context,
      result.completed ? '双方已完成解约协议签署' : '房东已完成签署',
      type: AppToastType.success,
    );
    Navigator.of(context).pop(true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('解约协议详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || detail == null
          ? AppErrorView(message: '解约协议加载失败', onRetry: _load)
          : _content(detail),
      bottomNavigationBar: detail == null || _loading
          ? null
          : _bottomBar(detail),
    );
  }

  Widget _content(LandlordTerminationDetail detail) {
    final item = detail.item;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        120,
      ),
      children: [
        _section('解约信息', [
          _row('申请单号', item.applicationNo),
          _row('原合同编号', item.contractNo),
          _row('当前状态', item.statusText),
          _row('解约原因', detail.reason),
        ]),
        _section('房源与租客', [
          _row(
            '房源',
            [
              item.houseName,
              item.roomName,
            ].where((value) => value.isNotEmpty).join(' '),
          ),
          _row('地址', item.address),
          _row('租客', item.tenantName),
          _row('联系电话', item.tenantPhone),
        ]),
        _section('退租结算', [
          _row('预计退租日', item.expectedMoveOutDate),
          _row('实际退租日', detail.actualMoveOutDate),
          _row('退款金额', formatContractMoney(detail.refundAmount)),
          _row('扣款金额', formatContractMoney(detail.deductionAmount)),
        ]),
        _section('签署状态', [
          _row('租客', item.tenantSigned ? '已签署' : '待签署'),
          _row('房东', item.lessorSigned ? '已签署' : '待我签署'),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Divider(height: 24),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.right),
        ),
      ],
    ),
  );

  Widget _bottomBar(LandlordTerminationDetail detail) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: detail.canSign
          ? FilledButton(
              onPressed: _signing || _refreshing ? null : _sign,
              child: Text(_signing ? '正在发起签署…' : '确认并签署解约协议'),
            )
          : OutlinedButton(
              onPressed: _refreshing ? null : _pollStatus,
              child: Text(_refreshing ? '正在刷新…' : '刷新签署状态'),
            ),
    ),
  );
}
