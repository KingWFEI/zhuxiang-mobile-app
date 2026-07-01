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

class _MyLeasesPageState extends ConsumerState<MyLeasesPage> {
  var _showCurrent = true;
  var _redirectScheduled = false;

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
      final message =
          next.actionMessage ??
          (!next.isLoading && next.leases.isNotEmpty
              ? next.errorMessage
              : null);
      if (message == null || message == previous?.actionMessage) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        ref.read(leaseControllerProvider.notifier).clearFeedback();
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: ref.read(leaseControllerProvider.notifier).load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _LeaseHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _LeaseSegment(
                        showCurrent: _showCurrent,
                        onChanged: (value) {
                          setState(() => _showCurrent = value);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      108,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildContent(leaseState),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LeaseState state) {
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

    if (_showCurrent) {
      if (state.currentLeases.isEmpty) {
        return const LeaseEmptyView(message: '暂无当前租约');
      }
      return Column(
        children: [
          for (final lease in state.currentLeases) ...[
            _CurrentLeaseDashboard(
              lease: lease,
              isOperating: state.isOperating,
              onDetailTap: () => _openDetail(lease),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      );
    }

    if (state.historyLeases.isEmpty) {
      return const LeaseEmptyView(message: '暂无历史租约');
    }
    return Column(
      children: [
        for (final lease in state.historyLeases) ...[
          HistoryLeaseCard(lease: lease, onTap: () => _openDetail(lease)),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
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
}

class _CurrentLeaseDashboard extends StatelessWidget {
  const _CurrentLeaseDashboard({
    required this.lease,
    required this.isOperating,
    required this.onDetailTap,
  });

  final Lease lease;
  final bool isOperating;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isOperating,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isOperating ? 0.65 : 1,
        child: CurrentLeaseCard(lease: lease, onTap: onDetailTap),
      ),
    );
  }
}

class _LeaseHeader extends StatelessWidget {
  const _LeaseHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FAFF), Color(0xFFE7F3FF)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.card),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -AppSpacing.lg,
            left: -AppSpacing.xl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.goNamed(RouteNames.home);
                },
                icon: AppIcon.iconBack,
              ),
            ),
          ),
          Positioned(
            right: -54,
            bottom: -54,
            child: Opacity(
              opacity: 0.42,
              child: Image.asset('assets/home_bk.png', width: 300),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 48),
                  const Icon(
                    Icons.home_work,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '住享',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 26),
                      Positioned(
                        right: 1,
                        top: 1,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '我的租约',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 30),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('租约信息清晰透明，安心居住每一天', style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaseSegment extends StatelessWidget {
  const _LeaseSegment({required this.showCurrent, required this.onChanged});

  final bool showCurrent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: '当前租约',
              selected: showCurrent,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentItem(
              label: '历史租约',
              selected: !showCurrent,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
