import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icon.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/legal/data/models/app_legal_document.dart';
import '../../features/legal/data/providers/app_legal_document_providers.dart';

/// 从服务端加载并以 Markdown 展示用户协议或隐私政策。
class StaticContentPage extends ConsumerStatefulWidget {
  const StaticContentPage({required this.documentType, super.key});

  final String documentType;

  @override
  ConsumerState<StaticContentPage> createState() => _StaticContentPageState();
}

class _StaticContentPageState extends ConsumerState<StaticContentPage> {
  AppLegalDocument? _document;
  String? _error;
  var _loading = true;

  String get _fallbackTitle =>
      widget.documentType == 'USER_AGREEMENT' ? '用户协议' : '隐私政策';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void didUpdateWidget(covariant StaticContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentType != widget.documentType) {
      _document = null;
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final document = await ref
          .read(appLegalDocumentServiceProvider)
          .getDocument(widget.documentType);
      if (!mounted) return;
      setState(() => _document = document);
    } on Object catch (_) {
      if (!mounted) return;
      setState(() => _error = '内容加载失败，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _document?.title.isNotEmpty == true
        ? _document!.title
        : _fallbackTitle;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _StaticContentHeader(title: title),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => _loadDocument(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    final document = _document;
    if (document == null || document.contentMarkdown.trim().isEmpty) {
      return Center(child: Text('暂无内容', style: AppTextStyles.bodyMedium));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      child: MarkdownBody(
        data: document.contentMarkdown,
        selectable: true,
        softLineBreak: true,
        onTapLink: (text, href, title) => _openMarkdownLink(href),
        styleSheet: MarkdownStyleSheet.fromTheme(
          Theme.of(context),
        ).copyWith(p: AppTextStyles.bodyMedium.copyWith(height: 1.8)),
      ),
    );
  }

  Future<void> _openMarkdownLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null ||
        !{'http', 'https', 'mailto', 'tel'}.contains(uri.scheme)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StaticContentHeader extends StatelessWidget {
  const _StaticContentHeader({required this.title});

  final String title;

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
            const SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StaticContentBackButton(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(title, style: AppTextStyles.normalPageTitle),
              ),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

class _StaticContentBackButton extends StatelessWidget {
  const _StaticContentBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.goNamed(RouteNames.home);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: AppIcon.iconBack,
      ),
    );
  }
}
