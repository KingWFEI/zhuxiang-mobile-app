import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_icon.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../application/repair_controller.dart';
import '../../data/providers/repair_providers.dart';
import '../../domain/entities/repair_order.dart';
import '../widgets/repair_order_card.dart';
import '../widgets/repair_rating_sheet.dart';
import '../widgets/repair_status_badge.dart';
import '../widgets/repair_timeline.dart';

class RepairDetailPage extends ConsumerWidget {
  const RepairDetailPage({required this.repairId, super.key});

  final String repairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(repairControllerProvider);
    final order = state.orderById(repairId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _PageHeader(title: '报修详情')),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildContent(context, ref, state, order),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    RepairState state,
    RepairOrder? order,
  ) {
    if (state.isLoading && order == null) {
      return const SizedBox(
        height: 420,
        child: AppLoadingView(message: '正在加载报修详情'),
      );
    }
    if (order == null) {
      return SizedBox(
        height: 420,
        child: AppErrorView(
          message: '报修详情加载失败',
          onRetry: ref.read(repairControllerProvider.notifier).load,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(order: order),
        const SizedBox(height: AppSpacing.lg),
        _InfoCard(
          title: '报修基础信息',
          children: [
            _InfoRow(label: '工单编号', value: order.orderNo),
            _InfoRow(label: '报修类型', value: order.repairTypeText),
            _InfoRow(label: '房源名称', value: order.houseName),
            _InfoRow(
              label: '提交时间',
              value: formatRepairDateTime(order.createdAt),
            ),
            _InfoRow(
              label: '期望上门',
              value: order.expectedVisitTime == null
                  ? '未填写'
                  : formatRepairDateTime(order.expectedVisitTime!),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _InfoCard(
          title: '问题描述',
          children: [Text(order.description, style: AppTextStyles.bodyMedium)],
        ),
        const SizedBox(height: AppSpacing.lg),
        _InfoCard(
          title: '图片列表',
          children: [
            if (order.imageUrls.isEmpty)
              Text(
                '暂无图片',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final _ in order.imageUrls)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _InfoCard(
          title: '联系人信息',
          children: [
            _InfoRow(label: '联系人', value: order.contactName),
            _InfoRow(label: '联系电话', value: order.contactPhone),
            _InfoRow(label: '处理管家', value: order.housekeeperName),
            _InfoRow(label: '管家电话', value: order.housekeeperPhone),
            if (order.repairmanName.isNotEmpty)
              _InfoRow(label: '维修人员', value: order.repairmanName),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _InfoCard(
          title: '维修进度',
          children: [RepairTimeline(items: order.timeline)],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (order.status.canReview)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => _showReviewSheet(context, ref, order),
              child: const Text('去评价'),
            ),
          )
        else if (order.rating != null)
          _InfoCard(
            title: '我的评价',
            children: [
              Row(
                children: [
                  for (var index = 1; index <= 5; index++)
                    Icon(
                      index <= order.rating!
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(order.reviewContent ?? '', style: AppTextStyles.bodyMedium),
            ],
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final RepairOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.home_repair_service_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(order.houseName, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          RepairStatusBadge(status: order.status),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
