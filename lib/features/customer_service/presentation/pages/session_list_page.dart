import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/providers/cs_providers.dart';
import '../../domain/entities/cs_entities.dart';

/// 历史会话列表页
class SessionListPage extends ConsumerStatefulWidget {
  const SessionListPage({super.key});

  @override
  ConsumerState<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends ConsumerState<SessionListPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // 推迟到首帧渲染完成后加载，避免在页面转场动画期间触发 rebuild 导致 ANR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sessionListProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.extentAfter < 240) {
      ref.read(sessionListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('历史会话')),
      body: state.isLoading
          ? const AppLoadingView(message: '加载历史')
          : state.errorMessage != null && state.sessions.isEmpty
              ? AppErrorView(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(sessionListProvider.notifier).loadInitial(),
                )
              : state.sessions.isEmpty
                  ? const AppEmptyView(message: '暂无历史会话')
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(sessionListProvider.notifier).refresh(),
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal, AppSpacing.md,
                          AppSpacing.pageHorizontal, 120,
                        ),
                        itemCount: state.sessions.length +
                            (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, index) {
                          if (index == state.sessions.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                            );
                          }
                          final s = state.sessions[index];
                          return _HistoryCard(
                            session: s,
                            onTap: () => context.pushNamed(
                                RouteNames.customerServiceChat,
                                pathParameters: {'sessionId': s.id}),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session, required this.onTap});
  final CsSession session;
  final VoidCallback onTap;

  String _label(String? reason) => switch (reason) {
        'TIMEOUT' => '已超时',
        'USER_NEW_SESSION' => '已结束',
        'USER_CLOSED' => '已关闭',
        _ => session.isActive ? '进行中' : '已结束',
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: session.isActive
                    ? AppColors.primaryLight
                    : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(Icons.headset_mic_outlined,
                  color: session.isActive
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title ?? '新会话',
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(session.lastMessagePreview ?? '',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: session.isActive
                    ? AppColors.primaryLight
                    : const Color(0xFFF3F5F4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_label(session.closedReason),
                  style: TextStyle(
                      fontSize: 11,
                      color: session.isActive
                          ? AppColors.primary
                          : AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
