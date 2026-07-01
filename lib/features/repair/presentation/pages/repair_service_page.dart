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
import '../../application/repair_controller.dart';
import '../../data/providers/repair_providers.dart';
import '../../data/services/repair_service.dart';
import '../../domain/entities/repair_order.dart';
import '../widgets/current_repair_house_card.dart';
import '../widgets/repair_empty_view.dart';
import '../widgets/repair_order_card.dart';
import '../widgets/repair_rating_sheet.dart';
import '../widgets/repair_stats_card.dart';
import '../widgets/repair_type_grid.dart';

class RepairServicePage extends ConsumerWidget {
  const RepairServicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(repairControllerProvider, (previous, next) {
      final message = next.submitMessage;
      if (message == null || message == previous?.submitMessage) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      ref.read(repairControllerProvider.notifier).clearSubmitMessage();
    });

    final state = ref.watch(repairControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: ref.read(repairControllerProvider.notifier).load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _RepairHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildContent(context, ref, state),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, RepairState state) {
    if (state.isLoading && state.overview == null) {
      return const SizedBox(
        height: 420,
        child: AppLoadingView(message: '正在加载报修服务'),
      );
    }
    if (state.errorMessage != null && state.overview == null) {
      if (state.errorMessage == noActiveRepairLeaseMessage) {
        return const SizedBox(
          height: 420,
          child: RepairEmptyView(
            title: noActiveRepairLeaseMessage,
            subtitle: '签约并入住后，可在这里提交房屋报修',
          ),
        );
      }
      return SizedBox(
        height: 420,
        child: AppErrorView(
          message: state.errorMessage!,
          onRetry: ref.read(repairControllerProvider.notifier).load,
        ),
      );
    }

    final overview = state.overview;
    if (overview == null) return const RepairEmptyView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentRepairHouseCard(
          house: overview.currentHouse,
          onContact: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('联系${overview.currentHouse.housekeeperName}'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: '快捷报修',
          actionText: '新建报修',
          onAction: () => context.pushNamed(RouteNames.createRepair),
        ),
        const SizedBox(height: AppSpacing.md),
        RepairTypeGrid(
          selectedType: null,
          onSelected: (type) => context.pushNamed(
            RouteNames.createRepair,
            queryParameters: {'type': type.name},
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        RepairStatsCard(
          pendingCount: state.countByFilter(RepairStatusFilter.submitted),
          processingCount: state.countByFilter(RepairStatusFilter.processing),
          pendingReviewCount: state.countByFilter(
            RepairStatusFilter.pendingReview,
          ),
          completedCount: state.countByFilter(RepairStatusFilter.completed),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: '最近报修',
          actionText: '全部记录',
          onAction: () => context.pushNamed(RouteNames.repairRecords),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.recentOrders.isEmpty)
          const RepairEmptyView()
        else
          for (final order in state.recentOrders) ...[
            RepairOrderCard(
              order: order,
              onTap: () => context.pushNamed(
                RouteNames.repairDetail,
                pathParameters: {'repairId': order.id},
              ),
              onReview: order.status.canReview
                  ? () => _showReviewSheet(context, ref, order)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => context.pushNamed(RouteNames.createRepair),
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建报修'),
          ),
        ),
      ],
    );
  }

  Future<void> _showReviewSheet(
    BuildContext context,
    WidgetRef ref,
    RepairOrder order,
  ) async {
    final result = await showModalBottomSheet<RepairRatingResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => RepairRatingSheet(order: order),
    );
    if (result == null) return;
    await ref
        .read(repairControllerProvider.notifier)
        .submitReview(
          repairId: order.id,
          rating: result.rating,
          content: result.content,
        );
  }
}

class _RepairHeader extends StatelessWidget {
  const _RepairHeader();

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
          bottom: Radius.circular(AppRadius.xxl),
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
                  context.goNamed(RouteNames.profile);
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
                '报修服务',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 30),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('问题及时报修，管家全程跟进', style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const Spacer(),
        TextButton(onPressed: onAction, child: Text(actionText)),
      ],
    );
  }
}
