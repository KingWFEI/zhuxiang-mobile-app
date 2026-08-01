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
    final selectedHouse = state.selectedHouse ?? overview.currentHouse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RepairHousePicker(
          houses: overview.repairHouses,
          selectedHouse: selectedHouse,
          onChanged: (houseId) =>
              ref.read(repairControllerProvider.notifier).selectHouse(houseId),
          onContact: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('联系${selectedHouse.housekeeperName}')),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: '快捷报修',
          actionText: '新建报修',
          onAction: () => _openCreateRepair(context, selectedHouse),
        ),
        const SizedBox(height: AppSpacing.md),
        RepairTypeGrid(
          selectedType: null,
          onSelected: (type) =>
              _openCreateRepair(context, selectedHouse, type: type),
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
            onPressed: () => _openCreateRepair(context, selectedHouse),
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建报修'),
          ),
        ),
      ],
    );
  }

  void _openCreateRepair(
    BuildContext context,
    RepairHouse house, {
    RepairType? type,
  }) {
    context.pushNamed(
      RouteNames.createRepair,
      queryParameters: {
        'houseId': house.houseId,
        if (type != null) 'type': type.name,
      },
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
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.goNamed(RouteNames.profile);
                  },
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
                  '报修服务',
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

class _RepairHousePicker extends StatelessWidget {
  const _RepairHousePicker({
    required this.houses,
    required this.selectedHouse,
    required this.onChanged,
    required this.onContact,
  });

  final List<RepairHouse> houses;
  final RepairHouse selectedHouse;
  final ValueChanged<String> onChanged;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    if (houses.length <= 1) {
      return CurrentRepairHouseCard(house: selectedHouse, onContact: onContact);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('报修房源', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: selectedHouse.houseId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          items: [
            for (final house in houses)
              DropdownMenuItem<String>(
                value: house.houseId,
                child: Text(
                  house.houseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        CurrentRepairHouseCard(house: selectedHouse, onContact: onContact),
      ],
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
