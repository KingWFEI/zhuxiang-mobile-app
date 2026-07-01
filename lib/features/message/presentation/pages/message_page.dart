import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../application/message_controller.dart';
import '../../data/providers/message_providers.dart';
import '../../domain/entities/app_message.dart';
import '../widgets/message_item.dart';

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  static const _categories = <MessageCategory?>[
    null,
    MessageCategory.appointment,
    MessageCategory.lease,
    MessageCategory.bill,
    MessageCategory.repair,
    MessageCategory.lock,
    MessageCategory.system,
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) {
      ref.read(messageControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageControllerProvider);
    final controller = ref.read(messageControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                AppSpacing.md,
              ),
              child: const AppLogo(),
            ),
            SizedBox(height:15  ),
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, index) {
                        final category = _categories[index];
                        final active = category == state.category;
                        final unread = state.unreadCounts.forCategory(category);
                        return _CategoryChip(
                          label: category?.label ?? '全部',
                          unreadCount: unread,
                          active: active,
                          onTap: () => controller.selectCategory(category),
                        );
                      },
                    ),
                  ),
                  PopupMenuButton<_MessageMenuAction>(
                    tooltip: '更多',
                    enabled: !state.isMutating,
                    onSelected: (action) {
                      switch (action) {
                        case _MessageMenuAction.markAllRead:
                          _markAllRead(controller);
                        case _MessageMenuAction.clearRead:
                          _clearReadMessages(controller);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _MessageMenuAction.markAllRead,
                        child: Row(
                          children: [
                            Icon(Icons.done_all, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('全部已读'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _MessageMenuAction.clearRead,
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('清空已读'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildContent(state, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MessageState state, MessageController controller) {
    if (state.isInitialLoading && state.messages.isEmpty) {
      return const AppLoadingView(message: '正在加载消息');
    }
    if (state.errorMessage != null && state.messages.isEmpty) {
      return _RefreshableStateView(
        onRefresh: controller.refresh,
        child: AppErrorView(
          message: state.errorMessage!,
          onRetry: controller.loadInitial,
        ),
      );
    }
    if (state.messages.isEmpty) {
      return _RefreshableStateView(
        onRefresh: controller.refresh,
        child: const AppEmptyView(message: '暂无消息'),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.sm,
          AppSpacing.pageHorizontal,
          120,
        ),
        itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, index) {
          if (index == state.messages.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final message = state.messages[index];
          return MessageItem(
            message: message,
            onTap: () => _openMessage(message, controller),
            onDelete: () => _deleteMessage(message, controller),
            onDeleted: () => controller.handleDeletedMessage(message.id),
          );
        },
      ),
    );
  }

  Future<void> _openMessage(
    AppMessage message,
    MessageController controller,
  ) async {
    if (!message.isRead) {
      final marked = await controller.markAsRead(message);
      if (!marked && mounted) {
        AppToast.show(context, '标记已读失败，但仍可查看消息', type: AppToastType.error);
      }
    }
    if (!mounted) return;
    final target = _resolveTarget(message);
    if (target == null) {
      AppToast.show(context, '该消息暂无可跳转页面');
      return;
    }
    try {
      context.push(target);
    } on Object {
      AppToast.show(context, '消息目标页面暂不可用', type: AppToastType.error);
    }
  }

  String? _resolveTarget(AppMessage message) {
    final target = message.actionTarget?.trim();
    if (target != null && target.startsWith('/')) {
      return _isSupportedMessagePath(target) ? target : null;
    }

    final targetKey = target?.toLowerCase();
    final aliasedTarget = switch (targetKey) {
      'lease' || 'leases' => RoutePaths.lease,
      'bill' || 'bills' => RoutePaths.bill,
      'repair' || 'repairs' => RoutePaths.repairs,
      'appointment' || 'appointments' => RoutePaths.appointment,
      'lock' || 'locks' => RoutePaths.unlockRecords,
      _ => null,
    };
    if (aliasedTarget != null) return aliasedTarget;

    final type = message.actionType?.toLowerCase().trim() ?? '';
    final businessType = type.isNotEmpty
        ? type
        : message.category?.apiValue ?? '';
    if (businessType.contains('lease')) {
      return target == null ? RoutePaths.lease : '${RoutePaths.lease}/$target';
    }
    if (businessType.contains('repair')) {
      return target == null
          ? RoutePaths.repairs
          : '${RoutePaths.repairs}/$target';
    }
    if (businessType.contains('appointment')) return RoutePaths.appointment;
    if (businessType.contains('bill')) return RoutePaths.bill;
    if (businessType.contains('lock')) return RoutePaths.unlockRecords;
    return null;
  }

  bool _isSupportedMessagePath(String path) {
    return path == RoutePaths.lease ||
        path.startsWith('${RoutePaths.lease}/') ||
        path == RoutePaths.bill ||
        path == RoutePaths.repairs ||
        path.startsWith('${RoutePaths.repairs}/') ||
        path == RoutePaths.appointment ||
        path == RoutePaths.unlockRecords ||
        path == RoutePaths.search ||
        path.startsWith('${RoutePaths.search}/') ||
        path.startsWith('/rental-flow/');
  }

  Future<void> _markAllRead(MessageController controller) async {
    final success = await controller.markAllAsRead();
    if (!mounted) return;
    AppToast.show(
      context,
      success ? '已全部标记为已读' : '全部已读操作失败，请重试',
      type: success ? AppToastType.success : AppToastType.error,
    );
  }

  Future<bool> _deleteMessage(
    AppMessage message,
    MessageController controller,
  ) async {
    final success = await controller.deleteMessage(message.id);
    if (!success && mounted) {
      AppToast.show(context, '删除消息失败，请重试', type: AppToastType.error);
    }
    return success;
  }

  Future<void> _clearReadMessages(MessageController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空已读消息'),
        content: const Text('确定删除全部已读消息吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.clearReadMessages();
    if (!mounted) return;
    AppToast.show(
      context,
      success ? '已清空已读消息' : '清空失败，请重试',
      type: success ? AppToastType.success : AppToastType.error,
    );
  }
}

enum _MessageMenuAction { markAllRead, clearRead }

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.unreadCount,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int unreadCount;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              _UnreadBadge(
                count: unreadCount,
                active: active,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count, required this.active});

  final int count;
  final bool active;

  double get _size {
    if (count < 10) return 18;
    if (count < 100) return 22;
    return 26;
  }

  double get _fontSize {
    if (count < 10) return 10;
    if (count < 100) return 10;
    return 9;
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: active ? AppColors.primary : Colors.white,
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

class _RefreshableStateView extends StatelessWidget {
  const _RefreshableStateView({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: constraints.maxHeight, child: child),
        ),
      ),
    );
  }
}
