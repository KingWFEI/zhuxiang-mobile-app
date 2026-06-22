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
import '../../application/lock_record_controller.dart';
import '../../data/providers/lock_record_providers.dart';
import '../../domain/entities/unlock_record.dart';
import '../widgets/current_lock_status_card.dart';
import '../widgets/unlock_record_empty_view.dart';
import '../widgets/unlock_record_filter_bar.dart';
import '../widgets/unlock_record_item.dart';
import '../widgets/unlock_record_stats_card.dart';

class UnlockRecordsPage extends ConsumerWidget {
  const UnlockRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lockRecordControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: ref.read(lockRecordControllerProvider.notifier).load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _UnlockRecordsHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      108,
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    LockRecordState state,
  ) {
    if (state.isLoading && state.overview == null) {
      return const SizedBox(
        height: 420,
        child: AppLoadingView(message: '正在加载开门记录'),
      );
    }
    if (state.errorMessage != null && state.overview == null) {
      return SizedBox(
        height: 420,
        child: AppErrorView(
          message: '开门记录加载失败',
          onRetry: ref.read(lockRecordControllerProvider.notifier).load,
        ),
      );
    }

    final overview = state.overview;
    if (overview == null) return const UnlockRecordEmptyView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentLockStatusCard(status: overview.lockStatus),
        const SizedBox(height: AppSpacing.lg),
        UnlockRecordStatsCard(
          todayCount: state.todayCount,
          monthCount: state.monthCount,
          abnormalCount: state.abnormalCount,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('开门明细', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.md),
        UnlockRecordFilterBar(
          selectedFilter: state.selectedFilter,
          onSelected: ref
              .read(lockRecordControllerProvider.notifier)
              .selectFilter,
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.filteredRecords.isEmpty)
          const UnlockRecordEmptyView()
        else
          for (final record in state.filteredRecords) ...[
            UnlockRecordItem(
              key: ValueKey(record.id),
              record: record,
              onTap: () => _showRecordDetail(context, record),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  void _showRecordDetail(BuildContext context, UnlockRecord record) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('开门记录详情', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(label: '开锁方式', value: record.unlockMethod.label),
              _DetailRow(
                label: '开锁结果',
                value: record.unlockResult.label,
                valueColor: record.isSuccess
                    ? AppColors.success
                    : AppColors.error,
              ),
              _DetailRow(
                label: '开锁时间',
                value: formatRecordDateTime(record.unlockTime),
              ),
              _DetailRow(label: '房源名称', value: record.houseName),
              _DetailRow(label: '门锁名称', value: record.lockName),
              _DetailRow(
                label: '操作人',
                value: '${record.operatorName}（${record.operatorType.label}）',
              ),
              if (record.deviceName.isNotEmpty)
                _DetailRow(label: '操作设备', value: record.deviceName),
              if (!record.isSuccess && record.failureReason.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    '失败原因：${record.failureReason}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockRecordsHeader extends StatelessWidget {
  const _UnlockRecordsHeader();

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
                '开门记录',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 30),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('每一次开门都有迹可循，守护居住安全', style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
