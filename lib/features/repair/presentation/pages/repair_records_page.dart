import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../application/repair_controller.dart';
import '../../data/providers/repair_providers.dart';
import '../../domain/entities/repair_order.dart';
import '../widgets/repair_empty_view.dart';
import '../widgets/repair_order_card.dart';
import '../widgets/repair_rating_sheet.dart';

class RepairRecordsPage extends ConsumerWidget {
  const RepairRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const SliverToBoxAdapter(child: _PageHeader(title: '报修记录')),
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
        child: AppLoadingView(message: '正在加载报修记录'),
      );
    }
    if (state.errorMessage != null && state.overview == null) {
      return SizedBox(
        height: 420,
        child: AppApiErrorView(
          message: state.errorMessage,
          onRetry: ref.read(repairControllerProvider.notifier).load,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in RepairStatusFilter.values) ...[
                ChoiceChip(
                  label: Text(filter.label),
                  selected: state.selectedFilter == filter,
                  onSelected: (_) => ref
                      .read(repairControllerProvider.notifier)
                      .selectFilter(filter),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.filteredOrders.isEmpty)
          const RepairEmptyView()
        else
          for (final order in state.filteredOrders) ...[
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: AppSpacing.sm,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed(RouteNames.repairs);
              },
              icon: AppIcon.iconBack,
            ),
          ),
          Text(title, style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}
