import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/landlord_house.dart';
import '../../data/providers/landlord_providers.dart';

class LandlordHouseListPage extends ConsumerStatefulWidget {
  const LandlordHouseListPage({super.key});

  @override
  ConsumerState<LandlordHouseListPage> createState() =>
      _LandlordHouseListPageState();
}

class _LandlordHouseListPageState extends ConsumerState<LandlordHouseListPage> {
  String? _statusFilter;
  final _processingHouseIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(landlordHousesProvider(_statusFilter));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('房源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '发布房源',
            onPressed: () => context.pushNamed('landlordHouseCreate'),
          ),
        ],
      ),
      body: result.when(
        loading: () => const AppLoadingView(message: '正在加载房源列表'),
        error: (error, _) => AppErrorView(
          message: '房源列表加载失败',
          onRetry: () => ref.invalidate(landlordHousesProvider(_statusFilter)),
        ),
        data: (houses) {
          if (houses.isEmpty) {
            return Column(
              children: [
                _StatusFilterBar(
                  selected: _statusFilter,
                  onChanged: (s) => setState(() => _statusFilter = s),
                ),
                const Expanded(child: AppEmptyView(message: '暂无房源，点击右上角发布')),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(landlordHousesProvider(_statusFilter)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.md,
                AppSpacing.pageHorizontal,
                96,
              ),
              children: [
                _StatusFilterBar(
                  selected: _statusFilter,
                  onChanged: (s) => setState(() => _statusFilter = s),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final house in houses) ...[
                  _HouseCard(
                    house: house,
                    isProcessing: _processingHouseIds.contains(house.id),
                    onPublish: () => _changeHouseStatus(house, publish: true),
                    onOffline: () => _changeHouseStatus(house, publish: false),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeHouseStatus(
    LandlordHouseItem house, {
    required bool publish,
  }) async {
    if (_processingHouseIds.contains(house.id)) return;
    setState(() => _processingHouseIds.add(house.id));
    try {
      final service = ref.read(landlordHouseServiceProvider);
      if (publish) {
        await service.publishHouse(house.id);
      } else {
        await service.offlineHouse(house.id);
      }
      if (!mounted) return;
      AppToast.show(
        context,
        publish ? '房源上架成功' : '房源下架成功',
        type: AppToastType.success,
      );
      ref.invalidate(landlordHousesProvider(_statusFilter));
    } on Object catch (error) {
      if (!mounted) return;
      AppToast.show(
        context,
        '${publish ? '上架' : '下架'}失败：$error',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _processingHouseIds.remove(house.id));
      }
    }
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _filters = [
    (null, '全部'),
    ('available', '已上架'),
    ('draft', '草稿'),
    ('offline', '已下架'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (value, label) = _filters[index];
          final active = selected == value;
          return ChoiceChip(
            selected: active,
            label: Text(label),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.primaryLight,
            side: BorderSide(
              color: active ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onChanged(value),
          );
        },
      ),
    );
  }
}

class _HouseCard extends StatelessWidget {
  const _HouseCard({
    required this.house,
    required this.isProcessing,
    required this.onPublish,
    required this.onOffline,
  });

  final LandlordHouseItem house;
  final bool isProcessing;
  final VoidCallback onPublish;
  final VoidCallback onOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.pushNamed(
            'landlordHouseEdit',
            pathParameters: {'houseId': house.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        width: 72,
                        height: 56,
                        child: house.coverImage.isEmpty
                            ? Container(
                                color: AppColors.primarySoft,
                                child: const Icon(
                                  Icons.home_work_outlined,
                                  color: AppColors.primary,
                                ),
                              )
                            : Image.network(
                                house.coverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.primarySoft,
                                  child: const Icon(
                                    Icons.home_work_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            house.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            house.location,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Text(
                                '¥${house.priceYuan}/月',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  house.statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _quickAction(
                      icon: Icons.edit_outlined,
                      label: '编辑',
                      onTap: () => context.pushNamed(
                        'landlordHouseEdit',
                        pathParameters: {'houseId': house.id},
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    if (house.status == 'available')
                      _quickAction(
                        icon: Icons.visibility_off_outlined,
                        label: '下架',
                        loading: isProcessing,
                        onTap: isProcessing ? null : onOffline,
                      ),
                    if (house.status == 'draft' || house.status == 'offline')
                      _quickAction(
                        icon: Icons.publish_outlined,
                        label: '上架',
                        loading: isProcessing,
                        onTap: isProcessing ? null : onPublish,
                      ),
                    const SizedBox(width: AppSpacing.lg),
                    _quickAction(
                      icon: Icons.delete_outline,
                      label: '删除',
                      color: AppColors.textMuted,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _statusColor {
    return switch (house.status) {
      'available' => AppColors.success,
      'draft' => AppColors.warning,
      'offline' => AppColors.textMuted,
      'rented' => AppColors.primary,
      _ => AppColors.textSecondary,
    };
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? color,
    bool loading = false,
  }) {
    final c = onTap == null
        ? AppColors.textMuted
        : color ?? AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: c),
              )
            else
              Icon(icon, size: 16, color: c),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
