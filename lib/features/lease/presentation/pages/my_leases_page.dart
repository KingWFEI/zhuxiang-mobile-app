import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../application/lease_controller.dart';
import '../../data/providers/lease_providers.dart';
import '../../domain/entities/lease.dart';
import '../widgets/current_lease_card.dart';
import '../widgets/lease_empty_view.dart';

class MyLeasesPage extends ConsumerStatefulWidget {
  const MyLeasesPage({super.key, this.enforceAuthentication = true});

  final bool enforceAuthentication;

  @override
  ConsumerState<MyLeasesPage> createState() => _MyLeasesPageState();
}

class _MyLeasesPageState extends ConsumerState<MyLeasesPage>
    with SingleTickerProviderStateMixin {
  var _redirectScheduled = false;
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Lease> _activeLeases(List<Lease> leases) =>
      leases.where((l) => l.status == LeaseStatus.active).toList();
  List<Lease> _pendingLeases(List<Lease> leases) =>
      leases.where((l) => l.status == LeaseStatus.pending).toList();

  @override
  Widget build(BuildContext context) {
    final authState = widget.enforceAuthentication
        ? ref.watch(authControllerProvider)
        : null;
    final leaseState = ref.watch(leaseControllerProvider);

    if (authState != null && authState.isInitialized && !authState.isLoggedIn) {
      _scheduleLoginRedirect();
    }

    ref.listen<LeaseState>(leaseControllerProvider, (previous, next) {
      final message = next.actionMessage ??
          (!next.isLoading && next.leases.isNotEmpty
              ? next.errorMessage
              : null);
      if (message == null || message == previous?.actionMessage) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppToast.show(context, message,
            type: message.contains('失败') || message.contains('错误')
                ? AppToastType.error
                : AppToastType.success);
        ref.read(leaseControllerProvider.notifier).clearFeedback();
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _LeaseHeader(
                  onHistoryTap: () => context.pushNamed(RouteNames.leaseHistory),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sm,
                    AppSpacing.pageHorizontal,
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      insets: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppTextStyles.bodyMedium,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '当前租约'),
                      Tab(text: '待生效'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaseList(
                        _activeLeases(leaseState.leases),
                        '暂无履约中租约',
                        leaseState,
                      ),
                      _buildLeaseList(
                        _pendingLeases(leaseState.leases),
                        '暂无待生效租约',
                        leaseState,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaseList(
    List<Lease> leases,
    String emptyMessage,
    LeaseState state,
  ) {
    if (state.isLoading && state.leases.isEmpty) {
      return const SizedBox(
        height: 360,
        child: AppLoadingView(message: '正在加载租约信息'),
      );
    }
    if (state.errorMessage != null && state.leases.isEmpty) {
      return SizedBox(
        height: 360,
        child: AppErrorView(
          message: state.errorMessage!,
          onRetry: ref.read(leaseControllerProvider.notifier).load,
        ),
      );
    }

    if (leases.isEmpty) {
      return RefreshIndicator(
        onRefresh: ref.read(leaseControllerProvider.notifier).load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [LeaseEmptyView(message: emptyMessage)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: ref.read(leaseControllerProvider.notifier).load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.lg,
          AppSpacing.pageHorizontal,
          108,
        ),
        children: [
          for (final lease in leases) ...[
            _CurrentLeaseDashboard(
              lease: lease,
              isOperating: state.isOperating,
              onDetailTap: () => _openDetail(lease),
              onContractTap: () => _openContract(lease),
              onKeeperTap: () => _callKeeper(lease),
              onPayTap: () => _goPay(lease),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          const _SafetyNotice(),
        ],
      ),
    );
  }

  void _scheduleLoginRedirect() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.goNamed(RouteNames.login);
    });
  }

  void _openDetail(Lease lease) {
    context.pushNamed(
      RouteNames.leaseDetail,
      pathParameters: {'leaseId': lease.id},
    );
  }

  void _openContract(Lease lease) {
    if (lease.contractStatus != LeaseContractStatus.signed) {
      context.pushNamed(RouteNames.rentOrders);
      return;
    }
    context.pushNamed(
      RouteNames.leaseContractView,
      pathParameters: {'leaseId': lease.id},
    );
  }

  void _callKeeper(Lease lease) {
    final phone = lease.keeperPhone;
    if (phone.isEmpty) return;
    AppToast.show(context, '管家电话：$phone');
  }

  void _goPay(Lease lease) {
    context.pushNamed(RouteNames.bill);
  }
}

class _CurrentLeaseDashboard extends StatelessWidget {
  const _CurrentLeaseDashboard({
    required this.lease,
    required this.isOperating,
    required this.onDetailTap,
    required this.onContractTap,
    required this.onKeeperTap,
    required this.onPayTap,
  });

  final Lease lease;
  final bool isOperating;
  final VoidCallback onDetailTap;
  final VoidCallback onContractTap;
  final VoidCallback onKeeperTap;
  final VoidCallback onPayTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isOperating,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isOperating ? 0.65 : 1,
        child: CurrentLeaseCard(
          lease: lease,
          onDetailTap: onDetailTap,
          onContractTap: onContractTap,
          onKeeperTap: onKeeperTap,
          onPayTap: onPayTap,
        ),
      ),
    );
  }
}

class _LeaseHeader extends StatelessWidget {
  const _LeaseHeader({this.onHistoryTap});

  final VoidCallback? onHistoryTap;

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
                child: _BackButton(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '我的租约',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: onHistoryTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        '历史租约',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

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

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '您的信息安全有保障，租约数据全程加密保护',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '如有疑问，请联系在线客服',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
