import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/router/app_mode_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/auth_controller.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                0,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: _buildHeader(controller),
            ),
            Expanded(child: _buildContent(state, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MessageController controller) {
    return SizedBox(
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -18,
            right: -40,
            child: Image.asset(
              'assets/home_bk.png',
              width: 300,
              fit: BoxFit.fitWidth,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogo(),
                  const Spacer(),
                  GestureDetector(
                    onTapDown: (_) => _showMessageMenu(controller),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSettings01,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessageMenu(MessageController controller) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => entry.remove(),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).padding.top + 46,
              right: AppSpacing.pageHorizontal,
              child: Material(
                borderRadius: BorderRadius.circular(14),
                elevation: 8,
                child: SizedBox(
                  width: 160,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuOption(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        label: '全部已读',
                        onTap: () {
                          entry.remove();
                          _markAllRead(controller);
                        },
                      ),
                      const Divider(height: 0),
                      _MenuOption(
                        icon: HugeIcons.strokeRoundedDelete02,
                        label: '清空已读',
                        onTap: () {
                          entry.remove();
                          _clearReadMessages(controller);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(entry);
  }

  Widget _buildContent(MessageState state, MessageController controller) {
    if (state.isInitialLoading && state.messages.isEmpty) {
      return const AppLoadingView(message: '正在加载消息');
    }
    if (state.errorMessage != null && state.messages.isEmpty) {
      return _RefreshableStateView(
        onRefresh: controller.refresh,
        child: AppApiErrorView(
          message: state.errorMessage!,
          onRetry: controller.loadInitial,
        ),
      );
    }

    final messages = state.messages;
    if (messages.isEmpty) {
      return _RefreshableStateView(
        onRefresh: controller.refresh,
        child: const AppEmptyView(message: '暂无消息'),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        itemCount: messages.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (_, index) {
          if (index == messages.length) {
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
          final message = messages[index];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: index == 0 ? const Radius.circular(22) : Radius.zero,
                bottom: index == messages.length - 1
                    ? const Radius.circular(22)
                    : Radius.zero,
              ),
              boxShadow: index == 0
                  ? const [
                      BoxShadow(
                        color: Color(0x0D5D7A9B),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: MessageItem(
              message: message,
              showDivider: index < messages.length - 1,
              onTap: () => _openMessage(message, controller),
              onDelete: () => _deleteMessage(message, controller),
              onDeleted: () => controller.handleDeletedMessage(message.id),
            ),
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
    final target = message.actionTarget;
    final isOrderMessage =
        target != null &&
        target.isNotEmpty &&
        (message.category == MessageCategory.bill ||
            message.actionType == 'order' ||
            message.actionType == 'rent_order');
    if (isOrderMessage) {
      // 当前租房订单以统一列表承载详情；兼容后端暂时下发 actionType=none。
      context.pushNamed(
        RouteNames.rentOrderDetail,
        pathParameters: {'orderId': target},
      );
      return;
    }
    if (message.actionType == 'appointment' &&
        message.actionTarget != null &&
        message.actionTarget!.isNotEmpty) {
      final isLandlord =
          ref.read(authControllerProvider).user?.role.usesLandlordShell ??
          false;
      final inLandlordMode = ref.read(appModeProvider) == AppMode.landlord;
      context.pushNamed(
        isLandlord && inLandlordMode
            ? RouteNames.landlordAppointmentDetail
            : RouteNames.viewingDetail,
        pathParameters: {'appointmentId': message.actionTarget!},
      );
      return;
    }
    context.pushNamed(
      RouteNames.messageDetail,
      pathParameters: {'messageId': message.id},
      extra: message,
    );
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

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label),
          ],
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
