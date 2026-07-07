import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/providers/cs_providers.dart';
import '../../data/services/customer_service_api.dart';
import '../../domain/entities/cs_entities.dart';

final _messagesProvider =
    FutureProvider.autoDispose.family<List<CsMessage>, String>(
  (ref, sessionId) async {
    final api = ref.read(csApiProvider);
    final result = await api.getMessages(sessionId);
    if (result is ApiSuccess<List<CsMessage>>) return result.data;
    if (result is ApiFailure<List<CsMessage>>) throw Exception(result.message);
    return [];
  },
);

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({this.sessionId, super.key});
  final String? sessionId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  String _streamingContent = '';
  StreamSubscription<SseEvent>? _sseSub;
  final List<CsMessage> _messages = [];
  bool _historyLoaded = false;
  Timer? _dotsTimer;
  int _dotsCount = 0;
  String? _resolvedSessionId;
  bool _isEntering = false;

  static const _quickQuestions = [
    '我的租约', '我的账单', '门锁打不开',
    '预约看房', '报修进度', '押金怎么退',
  ];

  String get _effectiveSessionId => _resolvedSessionId ?? widget.sessionId ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _resolvedSessionId = widget.sessionId;
    } else {
      _enter();
    }
  }

  Future<void> _enter() async {
    if (_isEntering) return;
    _isEntering = true;
    final api = ref.read(csApiProvider);
    final result = await api.enterSession();
    if (!mounted) return;
    if (result is ApiSuccess<EnterSessionResponse>) {
      setState(() => _resolvedSessionId = result.data.sessionId);
    } else {
      final r2 = await api.createSession();
      if (!mounted) return;
      if (r2 is ApiSuccess<CsSession>) {
        setState(() => _resolvedSessionId = r2.data.id);
      }
    }
    _isEntering = false;
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _sseSub?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _startNewSession() async {
    final api = ref.read(csApiProvider);
    final r = await api.createSession();
    if (!mounted) return;
    if (r is ApiSuccess<CsSession>) {
      setState(() {
        _resolvedSessionId = r.data.id;
        _messages.clear();
        _historyLoaded = false;
        _isSending = false;
        _streamingContent = '';
      });
    } else {
      AppToast.show(context, '创建失败', type: AppToastType.error);
    }
  }

  void _sendMessage([String? text]) {
    final t = (text ?? _inputCtrl.text).trim();
    if (t.isEmpty || _isSending) return;
    _inputCtrl.clear();

    // 立即添加用户消息
    final userMsg = CsMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _effectiveSessionId, role: 'USER',
      content: t, status: 'SENT', createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isSending = true;
      _streamingContent = '';
    });
    // 启动等待点动画
    _dotsCount = 0;
    _dotsTimer?.cancel();
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _dotsCount = (_dotsCount + 1) % 4);
    });
    _scrollToBottom();

    final api = ref.read(csApiProvider);
    _sseSub?.cancel();
    _sseSub = api.streamMessage(sessionId: _effectiveSessionId, message: t).listen(
      (e) {
        if (!mounted) return;
        final j = e.jsonData;
        switch (e.event) {
          case 'delta':
            _dotsTimer?.cancel();
            final c = j?['content'] as String? ?? '';
            if (c.isNotEmpty) setState(() => _streamingContent += c);
          case 'done':
            _dotsTimer?.cancel();
            final answer = j?['answer'] as String? ?? _streamingContent;
            final ai = CsMessage(
              id: 'd_${DateTime.now().millisecondsSinceEpoch}',
              sessionId: _effectiveSessionId, role: 'ASSISTANT',
              content: answer, status: 'DONE', createdAt: DateTime.now(),
            );
            setState(() {
              _messages.add(ai);
              _streamingContent = '';
              _isSending = false;
            });
            ref.invalidate(_messagesProvider(_effectiveSessionId));
            _scrollToBottom();
          case 'session_timeout':
            _dotsTimer?.cancel();
            setState(() => _isSending = false);
            AppToast.show(context, '会话已超时，请重新进入', type: AppToastType.error);
          case 'error':
            _dotsTimer?.cancel();
            if (_streamingContent.isNotEmpty) {
              _messages.add(CsMessage(
                id: 'e_${DateTime.now().millisecondsSinceEpoch}',
                sessionId: _effectiveSessionId, role: 'ASSISTANT',
                content: '$_streamingContent\n\n（回复中断）',
                status: 'FAILED', createdAt: DateTime.now(),
              ));
            }
            setState(() { _streamingContent = ''; _isSending = false; });
            AppToast.show(context, j?['message'] as String? ?? '回复失败', type: AppToastType.error);
        }
      },
      onError: (_) { if (mounted) setState(() => _isSending = false); },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sid = _effectiveSessionId;
    if (sid.isEmpty || _isEntering) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F5F4),
        appBar: AppBar(title: const Text('智能客服')),
        body: const Center(child: AppLoadingView(message: '进入智能客服...')),
      );
    }

    final async = ref.watch(_messagesProvider(sid));
    ref.listen(_messagesProvider(sid), (_, next) {
      if (!_historyLoaded && next is AsyncData<List<CsMessage>>) {
        _historyLoaded = true;
        setState(() {
          _messages.replaceRange(0, _messages.length, next.value);
        });
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F4),
      appBar: AppBar(
        title: const Text('智能客服'),
        actions: [
          IconButton(icon: const Icon(Icons.add_comment_outlined, size: 20),
              tooltip: '新建会话', onPressed: _startNewSession),
          IconButton(icon: const Icon(Icons.history, size: 20),
              tooltip: '历史会话',
              onPressed: () => context.pushNamed(RouteNames.customerService)),
        ],
      ),
      body: Column(children: [Expanded(child: _body(async)), _inputBar()]),
    );
  }

  Widget _body(AsyncValue<List<CsMessage>> async) {
    if (_messages.isEmpty && !_historyLoaded && async is AsyncLoading) {
      return const Center(child: AppLoadingView(message: '加载消息'));
    }
    if (_messages.isEmpty && !_isSending) {
      return _welcome();
    }
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal,
          AppSpacing.md, AppSpacing.pageHorizontal, AppSpacing.lg),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length && _isSending) {
          return _bubble(
            isUser: false,
            content: _streamingContent,
            streaming: _streamingContent.isEmpty,
            dots: _streamingContent.isEmpty ? _dotsCount : 0,
          );
        }
        final m = _messages[i];
        return _bubble(isUser: m.isUser, content: m.content, streaming: false);
      },
    );
  }

  Widget _welcome() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal, vertical: 48),
      children: [
        const Center(child: Icon(Icons.headset_mic_outlined, size: 56, color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.lg),
        const Center(child: Text('你好，我是住享智能客服', style: AppTextStyles.titleMedium)),
        const SizedBox(height: AppSpacing.sm),
        const Center(child: Text('可以帮你查询租约、账单、门锁、预约和报修问题',
            style: TextStyle(color: AppColors.textSecondary))),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
          children: _quickQuestions.map((q) => ActionChip(
            label: Text(q, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            backgroundColor: AppColors.primaryLight,
            side: BorderSide.none,
            onPressed: () => _sendMessage(q),
          )).toList(),
        ),
      ],
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
        decoration: const BoxDecoration(color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _inputCtrl, enabled: !_isSending,
            decoration: InputDecoration(
              hintText: '输入消息...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              filled: true, fillColor: const Color(0xFFF3F5F4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              isDense: true,
            ),
            style: AppTextStyles.bodyMedium,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
          )),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 40, height: 40,
            child: IconButton(
              onPressed: _isSending ? null : () => _sendMessage(),
              icon: Icon(Icons.send_rounded,
                  color: _isSending ? AppColors.textMuted : AppColors.primary, size: 22),
              padding: EdgeInsets.zero,
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _bubble({
  required bool isUser,
  required String content,
  required bool streaming,
  int dots = 0,
}) {
  final showDots = dots > 0 && content.isEmpty;
  final displayText = showDots ? '.' * dots : (content.isEmpty ? '...' : content);
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(AppRadius.md)),
            alignment: Alignment.center,
            child: const Icon(Icons.headset_mic, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.xl),
              topRight: const Radius.circular(AppRadius.xl),
              bottomLeft: Radius.circular(isUser ? AppRadius.xl : AppRadius.sm),
              bottomRight: Radius.circular(isUser ? AppRadius.sm : AppRadius.xl),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(displayText,
                key: ValueKey(displayText),
                style: AppTextStyles.bodyMedium.copyWith(
                    color: isUser ? Colors.white : AppColors.textPrimary, height: 1.55)),
          ),
        )),
        if (isUser) const SizedBox(width: AppSpacing.sm),
      ],
    ),
  );
}
