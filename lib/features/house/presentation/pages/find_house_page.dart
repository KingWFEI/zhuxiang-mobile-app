import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/features/house/data/models/house.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/location/user_location_provider.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../home/presentation/widgets/home_search_bar.dart';
import '../../application/house_search_notifier.dart';
import '../../data/providers/house_providers.dart';
import '../widgets/city_selection_sheet.dart';
import '../widgets/house_card.dart';
import '../widgets/house_filter_bar.dart';
import '../widgets/house_filter_sheets.dart';
import '../widgets/house_location_header.dart';
import '../widgets/house_quick_tags.dart';
import '../widgets/house_sort_sheet.dart';
import '../widgets/search_result_widgets.dart';
import '../widgets/skeleton_house_list.dart';

/// 找房 Tab 首页，负责展示定位、快捷筛选和推荐房源。
class FindHomePage extends ConsumerStatefulWidget {
  const FindHomePage({super.key});

  @override
  ConsumerState<FindHomePage> createState() => _FindHomePageState();
}

class _FindHomePageState extends ConsumerState<FindHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    // 进入页面时执行一次不带关键词的搜索
    Future<void>.microtask(
      () => ref.read(houseSearchProvider.notifier).search(),
    );
    // 首次进入时自动获取位置（启动阶段已用缓存，这里很快），失败才弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoLocateIfNeeded());
  }

  Future<void> _autoLocateIfNeeded() async {
    if (!mounted) return;
    final loc = ref.read(userLocationProvider);
    if (loc.hasSelection) {
      debugPrint('[FIND_HOUSE] city already set: ${loc.city}');
      return;
    }
    debugPrint('[FIND_HOUSE] no city, auto-fetching location');
    await ref.read(userLocationProvider.notifier).fetch();
    if (!mounted) return;
    final after = ref.read(userLocationProvider);
    if (!after.hasSelection) {
      debugPrint('[FIND_HOUSE] auto-fetch failed, showing toast');
      AppToast.show(context, '定位失败，请检查是否打开定位权限', type: AppToastType.error);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  /// 滚动接近列表底部时预加载下一页。
  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 320) {
      ref.read(houseSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(houseSearchProvider);
    final notifier = ref.read(houseSearchProvider.notifier);
    final location = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
            unawaited(ref.read(userLocationProvider.notifier).refresh());
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                  AppSpacing.pageHorizontal,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HouseLocationHeader(
                        city: location.hasSelection ? location.city : (location.error != null ? '重新定位' : '选择城市'),
                        district: location.hasSelection ? location.district : '',
                        onMapTap: () => CitySelectionSheet.show(context),
                      ),
                      SizedBox(
                        width: 220,
                        child: HomeSearchBar(
                          hintText: '搜索小区、地铁、区域或房源',
                          onTap: _openSearchPage,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    0,
                    AppSpacing.pageHorizontal,
                    0,
                  ),
                  child: HouseFilterBar(
                    region: state.region,
                    minPrice: state.minPrice,
                    maxPrice: state.maxPrice,
                    roomType: state.roomType,
                    sort: state.sort,
                    onRegionTap: _showRegionSheet,
                    onRentTap: _showRentSheet,
                    onRoomTap: _showRoomSheet,
                    onSortTap: _showSortSheet,
                    onMoreTap: _showMoreSheet,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    5,
                    AppSpacing.pageHorizontal,
                    0,
                  ),
                  child: _buildQuickTags(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                  AppSpacing.pageHorizontal,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: HouseListHeader(countText: '${state.totalCount}'),
                ),
              ),
              if (state.isLoading && state.houses.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    0,
                    AppSpacing.pageHorizontal,
                    AppSpacing.pageHorizontal,
                  ),
                  sliver: SkeletonHouseList(),
                )
              else if (state.error != null && state.houses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorView(
                    message: state.error!,
                    onRetry: notifier.search,
                  ),
                )
              else if (state.houses.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyView(message: '没有找到符合条件的房源'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    0,
                    AppSpacing.pageHorizontal,
                    AppSpacing.md,
                  ),
                  sliver: SliverList.separated(
                    itemCount: state.houses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final house = state.houses[index];
                      return HouseCard(
                        key: ValueKey(house.id),
                        house: house,
                        isFavorite: house.isFavorite,
                        onFavoriteTap: () => _toggleFavorite(house),
                        onTap: () => _openDetail(house),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(
                child: _PaginationFooter(
                  isLoading: state.isLoadingMore,
                  hasMore: state.hasMore,
                  hasData: state.houses.isNotEmpty,
                  error: state.houses.isEmpty ? null : state.error,
                  onRetry: notifier.loadMore,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开独立搜索页，避免在首页直接弹出键盘。
  void _openSearchPage() => context.pushNamed(RouteNames.houseSearch);

  /// 区域选择 BottomSheet。
  Future<void> _showRegionSheet() async {
    final selected = await showRegionSheet(context, selectedValue: ref.read(houseSearchProvider).region);
    if (selected == null || !mounted) return;
    ref.read(houseSearchProvider.notifier).updateRegion(selected);
  }

  /// 租金范围 BottomSheet。
  Future<void> _showRentSheet() async {
    final state = ref.read(houseSearchProvider);
    final result = await showRentSheet(context, minPrice: state.minPrice, maxPrice: state.maxPrice);
    if (result == null || !mounted) return;
    ref.read(houseSearchProvider.notifier).updatePriceRange(result.start.round(), result.end >= 1000000 ? 0 : result.end.round());
  }

  /// 户型选择 BottomSheet。
  Future<void> _showRoomSheet() async {
    final selected = await showRoomSheet(context, selectedValue: ref.read(houseSearchProvider).roomType);
    if (selected == null || !mounted) return;
    ref.read(houseSearchProvider.notifier).updateRoomType(selected);
  }

  /// 打开全屏筛选页并同步有效筛选字段。
  Future<void> _showSortSheet() async {
    final selected = await showHouseSortSheet(context, selectedValue: ref.read(houseSearchProvider).sort);
    if (selected == null || !mounted) return;
    final current = ref.read(houseSearchProvider);
    ref.read(houseSearchProvider.notifier).updateExtraFilters(
      sort: selected,
      decoration: current.decoration,
      orientation: current.orientation,
    );
  }

  /// 更多筛选条件 BottomSheet。
  Future<void> _showMoreSheet() async {
    final state = ref.read(houseSearchProvider);
    final result = await showMoreFilterSheet(
      context,
      sort: state.sort,
      decoration: state.decoration,
      orientation: state.orientation,
    );
    if (result == null || !mounted) return;
    ref.read(houseSearchProvider.notifier).updateExtraFilters(
      sort: result.sort,
      decoration: result.decoration,
      orientation: result.orientation,
    );
  }

  /// 从接口获取标签并组装成快捷标签组件。
  Widget _buildQuickTags() {
    final tagsAsync = ref.watch(houseTagsProvider);
    final activeTags = ref.watch(houseSearchProvider).activeTags;

    return tagsAsync.when(
      data: (houseTags) {
        if (houseTags.isEmpty) return const SizedBox.shrink();
        final items = houseTags
            .map((t) => QuickTagItem(label: t.label, value: t.value))
            .toList();
        return HouseQuickTags(
          tags: items,
          selectedTags: activeTags,
          onTagTap: _toggleQuickTag,
        );
      },
      loading: () => const SizedBox(
        height: 26,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  /// 切换快捷标签，通知搜索状态刷新列表。
  void _toggleQuickTag(String tag) {
    ref.read(houseSearchProvider.notifier).toggleTag(tag);
  }

  Future<void> _toggleFavorite(House house) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      context.pushNamed(RouteNames.login);
      return;
    }
    try {
      if (house.isFavorite) {
        await ref.read(houseServiceProvider).removeFavorite(house.id);
      } else {
        await ref.read(houseServiceProvider).addFavorite(house.id);
      }
      // 刷新列表以更新 isFavorite 状态
      ref.invalidate(houseSearchProvider);
    } on Object {
      if (mounted) AppToast.show(context, '操作失败，请稍后重试', type: AppToastType.error);
    }
  }

  /// 复用项目已有房源详情路由。
  void _openDetail(House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }

}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isLoading,
    required this.hasMore,
    required this.hasData,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasMore;
  final bool hasData;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!hasData) return const SizedBox.shrink();
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return TextButton(onPressed: onRetry, child: Text('$error，点击重试'));
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '已经到底了',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}
