import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_webview_page.dart';
import '../../data/models/real_name_auth_models.dart';
import '../../data/providers/real_name_auth_providers.dart';

class RealNameAuthPage extends ConsumerStatefulWidget {
  const RealNameAuthPage({
    this.continueHouseId,
    this.continueOrderId,
    super.key,
  });

  final String? continueHouseId;
  final String? continueOrderId;

  @override
  ConsumerState<RealNameAuthPage> createState() => _RealNameAuthPageState();
}

class _RealNameAuthPageState extends ConsumerState<RealNameAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _realNameController = TextEditingController();
  final _idCardController = TextEditingController();

  RealNameAuthStatusResponse? _localStatus;
  String? _authNo;
  String? _authUrl;
  DateTime? _authUrlExpireTime;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  bool _isOpeningAuth = false;
  Timer? _authExpireTimer;
  DateTime? _scheduledExpireAt;
  RealNameAuthStatus? _currentStatus;
  bool _expiryHandled = false;

  @override
  void initState() {
    super.initState();
    if (widget.continueHouseId?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppToast.show(context, '请先完成实名认证，认证成功后继续申请');
        }
      });
    }
  }

  @override
  void dispose() {
    _authExpireTimer?.cancel();
    _realNameController.clear();
    _idCardController.clear();
    _realNameController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remoteStatus = ref.watch(realNameAuthStatusProvider);
    final status = _localStatus == null
        ? remoteStatus
        : AsyncValue.data(_localStatus!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AuthHeader(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed(RouteNames.profile);
              },
            ),
            Expanded(
              child: status.when(
        loading: () => const AppLoadingView(message: '正在查询认证状态'),
        error: (error, stackTrace) => AppErrorView(
          message: _errorMessage(error),
          onRetry: () {
            _localStatus = null;
            ref.invalidate(realNameAuthStatusProvider);
          },
        ),
        data: _buildStatusContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(RealNameAuthStatusResponse status) {
    _syncAuthData(status);
    if (status.authStatus == RealNameAuthStatus.expired && !_expiryHandled) {
      _expiryHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAuthExpired();
      });
    }
    return RefreshIndicator(
      onRefresh: () => _refreshStatus(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          if (_shouldShowStatusCard(status.authStatus)) ...[
            _StatusCard(status: status),
            const SizedBox(height: AppSpacing.md),
          ],
          switch (status.authStatus) {
            RealNameAuthStatus.verified => _VerifiedContent(
              status: status,
              onContinue: _hasContinuation ? _continueAfterVerification : null,
            ),
            RealNameAuthStatus.verifying => _VerifyingContent(
              status: status,
              authUrlExpireTime: _authUrlExpireTime,
              isRefreshing: _isRefreshing,
              isOpeningAuth: _isOpeningAuth,
              onOpenAuth: _openOrRefreshAuthUrl,
              onRefresh: () => _refreshStatus(showLoading: true),
              onRestartAuth: _resetAuthForm,
            ),
            RealNameAuthStatus.unverified ||
            RealNameAuthStatus.failed ||
            RealNameAuthStatus.expired ||
            RealNameAuthStatus.canceled => _FormContent(
              formKey: _formKey,
              realNameController: _realNameController,
              idCardController: _idCardController,
              isSubmitting: _isSubmitting,
              status: status.authStatus,
              onSubmit: _startAuth,
            ),
            RealNameAuthStatus.unknown => _UnknownContent(
              onRefresh: () => _refreshStatus(showLoading: true),
            ),
          },
        ],
      ),
    );
  }

  void _syncAuthData(RealNameAuthStatusResponse status) {
    _currentStatus = status.authStatus;
    if (status.realNameAuthNo?.isNotEmpty == true) {
      _authNo = status.realNameAuthNo;
    }
    if (status.authUrl?.isNotEmpty == true) _authUrl = status.authUrl;
    if (status.authUrlExpireTime != null) {
      _authUrlExpireTime = status.authUrlExpireTime;
      _scheduleAuthExpiry(status.authUrlExpireTime!);
    } else if (status.authStatus != RealNameAuthStatus.verifying) {
      _authExpireTimer?.cancel();
      _authExpireTimer = null;
      _scheduledExpireAt = null;
    }
  }

  void _scheduleAuthExpiry(DateTime expireAt) {
    if (_scheduledExpireAt == expireAt) return;
    _authExpireTimer?.cancel();
    _scheduledExpireAt = expireAt;
    final delay = expireAt.difference(DateTime.now());
    _authExpireTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      _handleAuthExpired,
    );
  }

  Future<void> _handleAuthExpired() async {
    if (!mounted ||
        (_currentStatus != RealNameAuthStatus.verifying &&
            _currentStatus != RealNameAuthStatus.expired)) {
      return;
    }
    _authExpireTimer = null;
    _scheduledExpireAt = null;
    _expiryHandled = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('认证链接已过期'),
        content: const Text('本次实名认证链接已失效，请返回上一页重新发起认证。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('重新填写'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _authExpireTimer?.cancel();
    _authExpireTimer = null;
    _scheduledExpireAt = null;
    _authNo = null;
    _authUrl = null;
    _authUrlExpireTime = null;
    _currentStatus = RealNameAuthStatus.expired;
    _localStatus = const RealNameAuthStatusResponse(
      authStatus: RealNameAuthStatus.expired,
    );
    _realNameController.clear();
    _idCardController.clear();
    setState(() {});
  }

  void _resetAuthForm() {
    _authExpireTimer?.cancel();
    _authExpireTimer = null;
    _scheduledExpireAt = null;
    _expiryHandled = true;
    _authNo = null;
    _authUrl = null;
    _authUrlExpireTime = null;
    _currentStatus = RealNameAuthStatus.expired;
    _localStatus = const RealNameAuthStatusResponse(
      authStatus: RealNameAuthStatus.expired,
    );
    _realNameController.clear();
    _idCardController.clear();
    setState(() {});
  }

  bool get _canOpenAuth {
    final url = _authUrl;
    final expireTime = _authUrlExpireTime;
    return url?.isNotEmpty == true &&
        (expireTime == null || expireTime.isAfter(DateTime.now()));
  }

  Future<void> _startAuth() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);
    try {
      final response = await ref
          .read(realNameAuthApiProvider)
          .restart(
            realName: _realNameController.text.trim(),
            idCardNo: _idCardController.text.trim().toUpperCase(),
          );
      if (!mounted) return;
      _authNo = response.realNameAuthNo;
      _authUrl = response.authUrl;
      _authUrlExpireTime = response.authUrlExpireTime;
      _expiryHandled = false;
      _localStatus = response;
      _realNameController.clear();
      _idCardController.clear();
      setState(() => _isSubmitting = false);
      if (_authUrl?.isNotEmpty == true) await _openAuthUrl();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(error);
    }
  }

  Future<void> _refreshStatus({required bool showLoading}) async {
    if (_isRefreshing) return;
    if (showLoading && mounted) setState(() => _isRefreshing = true);
    _isRefreshing = true;
    try {
      final api = ref.read(realNameAuthApiProvider);
      final authNo = _authNo;
      final response = authNo?.isNotEmpty == true
          ? await api.refresh(authNo!)
          : await api.getStatus();
      if (!mounted) return;
      _localStatus = response;
      _syncAuthData(response);
      if (response.authStatus == RealNameAuthStatus.verified) {
        _authUrl = null;
        _authNo = null;
        _authUrlExpireTime = null;
        _realNameController.clear();
        _idCardController.clear();
      }
      setState(() {});
    } catch (error) {
      if (error is ApiException && error.statusCode == 409) {
        try {
          final response = await ref.read(realNameAuthApiProvider).getStatus();
          if (mounted) {
            _localStatus = response;
            _syncAuthData(response);
            setState(() {});
          }
        } catch (_) {
          if (mounted && showLoading) _showError(error);
        }
        return;
      }
      if (mounted && showLoading) _showError(error);
    } finally {
      _isRefreshing = false;
      if (mounted && showLoading) setState(() {});
    }
  }

  Future<void> _openAuthUrl() async {
    final value = _authUrl;
    if (value == null || value.isEmpty) {
      if (mounted) {
        AppToast.show(context, '当前没有可用的认证链接，请重新发起认证', type: AppToastType.error);
      }
      return;
    }
    if (!AppWebViewPage.supportsUrl(value)) {
      if (mounted) {
        AppToast.show(context, '无法打开实名认证页面', type: AppToastType.error);
      }
      return;
    }
    if (mounted) setState(() => _isOpeningAuth = true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AppWebViewPage(
            title: '实名认证',
            initialUrl: value,
            allowCamera: true,
          ),
        ),
      );
      if (mounted) await _refreshStatus(showLoading: false);
    } on Object {
      if (mounted) {
        AppToast.show(context, '无法打开实名认证页面', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isOpeningAuth = false);
    }
  }

  Future<void> _openOrRefreshAuthUrl() async {
    if (_isOpeningAuth) return;
    if (_canOpenAuth) {
      await _openAuthUrl();
      return;
    }
    final authNo = _authNo;
    if (authNo == null || authNo.isEmpty) {
      await _refreshStatus(showLoading: false);
      if (mounted) {
        if (_canOpenAuth) {
          await _openAuthUrl();
        } else {
          AppToast.show(
            context,
            '当前没有可用的认证链接，请重新发起认证',
            type: AppToastType.error,
          );
        }
      }
      return;
    }

    setState(() => _isOpeningAuth = true);
    try {
      final response = await ref.read(realNameAuthApiProvider).refresh(authNo);
      if (!mounted) return;
      _localStatus = response;
      _syncAuthData(response);
      setState(() {});
      if (response.authStatus == RealNameAuthStatus.verifying && _canOpenAuth) {
        await _openAuthUrl();
      } else if (mounted &&
          response.authStatus != RealNameAuthStatus.verified) {
        AppToast.show(context, '当前没有可用的认证链接，请重新发起认证', type: AppToastType.error);
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isOpeningAuth = false);
    }
  }

  void _continueAfterVerification() {
    final orderId = widget.continueOrderId;
    if (orderId?.isNotEmpty == true) {
      context.pushReplacementNamed(
        RouteNames.leaseContract,
        pathParameters: {'orderId': orderId!},
      );
      return;
    }
    if (widget.continueHouseId?.isNotEmpty == true) {
      context.pop(true);
    }
  }

  bool get _hasContinuation =>
      widget.continueHouseId?.isNotEmpty == true ||
      widget.continueOrderId?.isNotEmpty == true;

  void _showError(Object error) {
    AppToast.show(context, _errorMessage(error), type: AppToastType.error);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return switch (error.statusCode) {
        401 => '登录状态已失效，请重新登录',
        400 => '认证信息填写不正确，请检查后重试',
        403 => '无权操作该认证记录',
        404 => '认证记录不存在，请重新发起认证',
        409 => '已有实名认证或正在进行中的认证任务',
        500 => '实名认证服务暂时不可用，请稍后重试',
        _ =>
          error.type == ApiExceptionType.network ||
                  error.type == ApiExceptionType.timeout
              ? '网络异常，请稍后重试'
              : '实名认证操作失败，请稍后重试',
      };
    }
    return '实名认证操作失败，请稍后重试';
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.onBack});

  final VoidCallback onBack;

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
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppIcon.iconBack,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '实名认证',
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final RealNameAuthStatusResponse status;

  @override
  Widget build(BuildContext context) {
    final verified = status.authStatus == RealNameAuthStatus.verified;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: verified ? AppColors.successLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.badge_outlined,
            color: verified ? AppColors.success : AppColors.primary,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('实名认证', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(_statusLabel(status.authStatus)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.realNameController,
    required this.idCardController,
    required this.isSubmitting,
    required this.status,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController realNameController;
  final TextEditingController idCardController;
  final bool isSubmitting;
  final RealNameAuthStatus status;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status == RealNameAuthStatus.unknown) ...[
            _Notice(
              text: status == RealNameAuthStatus.failed
                  ? '认证失败，请确认信息后重新发起认证。'
                  : '认证链接已失效，请重新发起认证。',
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const _Notice(text: '实名认证用于保障租赁交易安全。平台不会保存身份证原件或人脸资料。'),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: realNameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: '真实姓名',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                value?.trim().isEmpty == true ? '请输入真实姓名' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: idCardController,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: '身份证号码',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
            validator: (value) {
              final text = value?.trim().toUpperCase() ?? '';
              if (!RegExp(r'^\d{17}[\dX]$').hasMatch(text)) {
                return '请输入正确的18位身份证号码';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('证件类型：中国大陆居民身份证'),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.face_retouching_natural),
            label: Text(isSubmitting ? '正在发起认证' : '开始人脸认证'),
          ),
        ],
      ),
    );
  }
}

class _VerifyingContent extends StatelessWidget {
  const _VerifyingContent({
    required this.status,
    required this.authUrlExpireTime,
    required this.isRefreshing,
    required this.isOpeningAuth,
    required this.onOpenAuth,
    required this.onRefresh,
    required this.onRestartAuth,
  });

  final RealNameAuthStatusResponse status;
  final DateTime? authUrlExpireTime;
  final bool isRefreshing;
  final bool isOpeningAuth;
  final VoidCallback? onOpenAuth;
  final VoidCallback onRefresh;
  final VoidCallback onRestartAuth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Notice(text: '请在 App 内完成人脸识别。关闭认证页面后会自动查询认证结果。'),
        const SizedBox(height: AppSpacing.md),
        if (status.idCardMasked != null)
          _InfoRow(label: '证件号码', value: status.idCardMasked!),
        if (authUrlExpireTime != null)
          _InfoRow(label: '链接有效期至', value: _formatDateTime(authUrlExpireTime!)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: isOpeningAuth ? null : onOpenAuth,
          icon: const Icon(Icons.web_asset_rounded),
          label: const Text('打开认证页面'),
        ),
        OutlinedButton.icon(
          onPressed: isRefreshing ? null : onRefresh,
          icon: isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(isRefreshing ? '正在查询' : '我已完成认证'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: isRefreshing || isOpeningAuth ? null : onRestartAuth,
          child: const Text('重新填写认证信息'),
        ),
      ],
    );
  }
}

class _VerifiedContent extends StatelessWidget {
  const _VerifiedContent({required this.status, this.onContinue});

  final RealNameAuthStatusResponse status;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoRow(label: '姓名', value: status.realNameMasked ?? '--'),
        _InfoRow(label: '证件号码', value: status.idCardMasked ?? '--'),
        _InfoRow(label: '平台手机号', value: status.accountMobileMasked ?? '--'),
        if (status.verifiedMobileMasked != null)
          _InfoRow(label: '核验手机号', value: status.verifiedMobileMasked!),
        if (status.verifiedAt != null)
          _InfoRow(label: '认证时间', value: _formatDateTime(status.verifiedAt!)),
        if (onContinue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('继续申请'),
          ),
        ],
      ],
    );
  }
}

class _UnknownContent extends StatelessWidget {
  const _UnknownContent({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Notice(text: '认证状态暂时无法识别，请刷新后重试。', color: AppColors.warning),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('刷新状态'),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.color = AppColors.primary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}

String _statusLabel(RealNameAuthStatus status) {
  return switch (status) {
    RealNameAuthStatus.unverified => '未认证',
    RealNameAuthStatus.verifying => '认证中',
    RealNameAuthStatus.verified => '已认证',
    RealNameAuthStatus.failed => '认证失败',
    RealNameAuthStatus.expired => '已过期',
    RealNameAuthStatus.canceled => '已取消',
    RealNameAuthStatus.unknown => '状态未知',
  };
}

bool _shouldShowStatusCard(RealNameAuthStatus status) {
  return status != RealNameAuthStatus.failed &&
      status != RealNameAuthStatus.expired &&
      status != RealNameAuthStatus.canceled;
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
