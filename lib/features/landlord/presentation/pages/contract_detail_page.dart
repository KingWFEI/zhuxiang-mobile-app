import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/landlord_contract.dart';
import '../../data/providers/landlord_providers.dart';

class LandlordContractDetailPage extends ConsumerStatefulWidget {
  const LandlordContractDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<LandlordContractDetailPage> createState() =>
      _LandlordContractDetailPageState();
}

enum _RejectDialogResult { rejectedSuccessfully, refreshRequired }

class _LandlordContractDetailPageState
    extends ConsumerState<LandlordContractDetailPage>
    with WidgetsBindingObserver {
  LandlordContractDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _signing = false;
  bool _rejecting = false;
  bool _refreshing = false;
  bool _openedSigner = false;
  bool _showManualRefresh = false;

  bool get _operationInProgress => _signing || _rejecting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedSigner && !_refreshing) {
      _openedSigner = false;
      _pollStatus();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(landlordContractServiceProvider)
          .getDetail(widget.orderId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (!mounted) return;
      if (_isForbidden(error)) {
        AppToast.show(context, '无权查看该合同', type: AppToastType.error);
        context.goNamed(RouteNames.landlordWorkbench);
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isForbidden(Object error) =>
      error is ApiException && error.statusCode == 403;

  Future<void> _sign() async {
    if (_operationInProgress || _detail?.canSign != true) return;
    setState(() {
      _signing = true;
      _showManualRefresh = false;
    });
    try {
      final result = await ref
          .read(landlordContractServiceProvider)
          .sign(widget.orderId);
      if (!mounted) return;
      if (result.currentUserSigned ||
          result.contractStatus.toUpperCase() == 'COMPLETED') {
        await _refreshStatus(showPendingMessage: false);
        return;
      }
      if (result.signUrl.isEmpty) {
        AppToast.show(context, '签署服务暂不可用', type: AppToastType.error);
        return;
      }
      _openedSigner = true;
      await context.pushNamed(
        RouteNames.landlordContractWebview,
        pathParameters: {'orderId': widget.orderId},
        extra: result.signUrl,
      );
      if (mounted && _openedSigner) {
        _openedSigner = false;
        await _pollStatus();
      }
    } catch (error) {
      if (!mounted) return;
      if (_isForbidden(error)) {
        AppToast.show(context, '无权操作该合同', type: AppToastType.error);
        context.goNamed(RouteNames.landlordWorkbench);
      } else {
        AppToast.show(
          context,
          error is ApiException ? error.message : '签署服务暂不可用',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  Future<void> _showRejectDialog() async {
    if (_operationInProgress || _detail?.canSign != true) return;
    final controller = TextEditingController();
    String? validationError;
    var submitting = false;
    var dialogClosedBySubmit = false;
    final result = await showDialog<_RejectDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            final reason = controller.text.trim();
            if (reason.isEmpty) {
              setDialogState(() => validationError = '请填写拒签原因');
              return;
            }
            if (reason.length > 500) {
              setDialogState(() => validationError = '拒签原因不能超过500字');
              return;
            }
            setDialogState(() {
              submitting = true;
              validationError = null;
            });
            if (mounted) setState(() => _rejecting = true);
            try {
              await ref
                  .read(landlordContractServiceProvider)
                  .reject(widget.orderId, reason);
              if (!mounted || !dialogContext.mounted) return;
              dialogClosedBySubmit = true;
              Navigator.of(
                dialogContext,
              ).pop(_RejectDialogResult.rejectedSuccessfully);
            } catch (error) {
              if (!mounted || !dialogContext.mounted) return;
              final apiError = error is ApiException ? error : null;
              final message = _rejectErrorMessage(apiError);
              AppToast.show(this.context, message, type: AppToastType.error);
              // 冲突和超时退出弹窗后再刷新详情，避免刷新父页面时销毁弹窗状态。
              if (apiError?.statusCode == 409 ||
                  apiError?.type == ApiExceptionType.timeout) {
                dialogClosedBySubmit = true;
                Navigator.of(
                  dialogContext,
                ).pop(_RejectDialogResult.refreshRequired);
              }
            } finally {
              // 弹窗已经 pop 后不能再 setDialogState，否则会在退场动画中触发红屏。
              if (!dialogClosedBySubmit && dialogContext.mounted) {
                setDialogState(() => submitting = false);
              }
            }
          }

          return PopScope(
            canPop: !submitting,
            child: AlertDialog(
              title: const Text('拒绝签署'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Text(
                        '拒绝签署后，该合同将终止，租客已支付款项将原路退回，房源将重新开放。此操作不可撤销。',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: controller,
                      enabled: !submitting,
                      maxLength: 500,
                      maxLines: 5,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '拒签原因（必填）',
                        hintText: '例如：合同信息无法确认',
                        errorText: validationError,
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setDialogState(() => validationError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('确认拒绝'),
                ),
              ],
            ),
          );
        },
      ),
    );
    controller.dispose();
    if (mounted) setState(() => _rejecting = false);

    if (result == _RejectDialogResult.rejectedSuccessfully && mounted) {
      AppToast.show(context, '已拒绝签署，退款正在处理', type: AppToastType.success);
      ref.invalidate(landlordPendingSignCountsProvider);
      // 返回“合同签署/待我签署”列表，列表页面会重新拉取并移除该订单。
      Navigator.of(context).pop(true);
      return;
    }
    if (result == _RejectDialogResult.refreshRequired && mounted) {
      await _load();
    }
  }

  String _rejectErrorMessage(ApiException? error) {
    if (error == null) return '拒绝签署失败，请稍后重试';
    if (error.type == ApiExceptionType.timeout) {
      return '请求结果暂未确认，请刷新合同状态';
    }
    if (error.statusCode == 403) return '无权操作该合同';
    if (error.statusCode == 409) {
      return switch (error.businessCode) {
        'ORDER_STATUS_INVALID' => '当前订单状态已发生变化，请刷新后重试',
        'LEASE_ALREADY_EXISTS' => '租约已经生成，无法拒绝签署',
        'ORDER_RESERVATION_LOST' => '房源占用已失效，请刷新订单',
        _ => error.message.isEmpty ? '订单状态冲突，请刷新后重试' : error.message,
      };
    }
    return error.message.isEmpty ? '拒绝签署失败，请稍后重试' : error.message;
  }

  Future<void> _pollStatus() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      for (var i = 0; i < 5; i++) {
        final status = await ref
            .read(landlordContractServiceProvider)
            .refresh(widget.orderId);
        if (!mounted) return;
        if (_handleStatus(status)) return;
        if (i < 4) await Future<void>.delayed(const Duration(seconds: 3));
      }
      if (mounted) {
        setState(() => _showManualRefresh = true);
        AppToast.show(context, '暂未查询到签署结果，请稍后刷新');
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          error is ApiException ? error.message : '状态刷新失败',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _refreshStatus({bool showPendingMessage = true}) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final status = await ref
          .read(landlordContractServiceProvider)
          .refresh(widget.orderId);
      if (!mounted) return;
      if (!_handleStatus(status) && showPendingMessage) {
        AppToast.show(context, '暂未查询到签署结果，请稍后刷新');
        await _load();
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          error is ApiException ? error.message : '状态刷新失败',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _handleStatus(ContractSignStatus status) {
    if (!status.currentUserSigned && !status.completed) return false;
    _showManualRefresh = false;
    ref.invalidate(landlordPendingSignCountsProvider);
    context.pushReplacementNamed(
      RouteNames.landlordContractResult,
      pathParameters: {'orderId': widget.orderId},
      queryParameters: {'result': status.completed ? 'completed' : 'waiting'},
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('合同详情')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || detail == null
          ? AppErrorView(message: '合同详情加载失败', onRetry: _load)
          : _content(detail),
      bottomNavigationBar: detail == null || _loading
          ? null
          : _bottomBar(detail),
    );
  }

  Widget _content(LandlordContractDetail detail) {
    final c = detail.contract;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        120,
      ),
      children: [
        _section('合同信息', [
          _row('合同编号', c.contractNo),
          _row(
            '房源',
            [c.houseName, c.roomName].where((e) => e.isNotEmpty).join(' '),
          ),
          _row('地址', c.houseAddress),
        ]),
        _section('签约双方', [
          _row('租客', c.tenantName),
          _row('租客手机', c.tenantPhone),
          _row('租客证件', maskIdCard(c.tenantIdCard)),
          _row('房东', c.landlordName),
          _row('房东手机', c.landlordPhone),
          _row('房东证件', maskIdCard(c.landlordIdCard)),
        ]),
        _section('租赁信息', [
          _row('租期', '${c.startDate} 至 ${c.endDate}'),
          _row('租期时长', '${c.leaseMonths}个月'),
          _row('月租', formatContractMoney(c.monthlyRent)),
          _row('押金', formatContractMoney(c.deposit)),
          _row('服务费', formatContractMoney(c.serviceFee)),
          _row('付款方式', _paymentLabel(c)),
        ]),
        _section('签署状态', [
          _row('租客', detail.tenantSigned ? '已签署' : '待签署'),
          _row('房东', detail.lessorSigned ? '已签署' : '待我签署'),
          if (detail.operationStatusLabel.isNotEmpty)
            _row('订单状态', detail.operationStatusLabel),
          if (detail.lessorSigned && !detail.tenantSigned)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '您已完成签署，正在等待租客签署',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          if (detail.unavailable)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '合同已撤销或过期，请联系客服',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ]),
        if (c.clauses.isNotEmpty)
          _section('合同条款', [
            for (var i = 0; i < c.clauses.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '${i + 1}. ${c.clauses[i]}',
                  style: const TextStyle(height: 1.55),
                ),
              ),
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
          width: 76,
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

  String _paymentLabel(ContractPreview c) {
    if (c.paymentMethod.isEmpty) {
      return c.paymentMonths > 0 ? '每${c.paymentMonths}个月支付' : '—';
    }
    return c.paymentMonths > 0
        ? '${c.paymentMethod}（每${c.paymentMonths}个月）'
        : c.paymentMethod;
  }

  Widget _bottomBar(LandlordContractDetail detail) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: detail.canSign
          ? _showManualRefresh
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _refreshing ? null : _refreshStatus,
                          child: Text(_refreshing ? '正在刷新…' : '刷新结果'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _operationInProgress || _refreshing
                              ? null
                              : _sign,
                          child: Text(_signing ? '正在发起…' : '重新发起'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _operationInProgress || _refreshing
                              ? null
                              : _showRejectDialog,
                          child: Text(_rejecting ? '正在拒签…' : '拒绝签署'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _operationInProgress || _refreshing
                              ? null
                              : _sign,
                          child: Text(_signing ? '正在发起签署…' : '签署合同'),
                        ),
                      ),
                    ],
                  )
          : OutlinedButton(
              onPressed: _refreshing ? null : _refreshStatus,
              child: Text(_refreshing ? '正在刷新…' : '刷新签署状态'),
            ),
    ),
  );
}
