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
import '../../application/house_search_notifier.dart';
import '../../data/models/house_filter_option.dart';
import '../../data/providers/house_providers.dart';
import '../widgets/house_card.dart';
import '../widgets/house_filter_bar.dart';
import '../widgets/house_filter_sheets.dart';
import '../widgets/house_sort_sheet.dart';
import '../widgets/search_result_widgets.dart';
import '../widgets/skeleton_house_list.dart';

/// 根据路由关键词展示完整房源列表的搜索结果页。
class HouseSearchResultPage extends ConsumerStatefulWidget {
  const HouseSearchResultPage({required this.keyword, super.key});

  final String keyword;

  @override
  ConsumerState<HouseSearchResultPage> createState() =>
      _HouseSearchResultPageState();
}

class _HouseSearchResultPageState extends ConsumerState<HouseSearchResultPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchKeyword());
  }

  @override
  void didUpdateWidget(covariant HouseSearchResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword) _searchKeyword();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  Future<void> _searchKeyword() async {
    await ref
        .read(houseSearchProvider.notifier)
        .selectKeyword(widget.keyword.trim());
  }

  /// 滚动到底部前预加载下一页。
  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 300) {
      ref.read(houseSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(houseSearchProvider);
    final notifier = ref.read(houseSearchProvider.notifier);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(houseSearchProvider.notifier).reset();
          return;
        }
        _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F9FF),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: SearchResultHeader(
                      keyword: widget.keyword,
                      onBack: _goBack,
                      onSearchTap: _openSearchPage,
                      onClear: _openSearchPage,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    10,
                    AppSpacing.xl,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: HouseFilterBar(
                      region: state.region,
                      minPrice: state.minPrice,
                      maxPrice: state.maxPrice,
                      roomType: state.roomType,
                      sort: state.sort,
                      moreActive:
                          state.decoration.isNotEmpty ||
                          state.orientation.isNotEmpty ||
                          state.rentMode.isNotEmpty ||
                          state.category.isNotEmpty ||
                          state.facilityIds.isNotEmpty ||
                          state.activeTags.isNotEmpty,
                      onRegionTap: _showRegionSheet,
                      onRentTap: _showRentSheet,
                      onRoomTap: _showRoomSheet,
                      onSortTap: _showSortSheet,
                      onMoreTap: _showMoreSheet,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: HouseListHeader(countText: '${state.totalCount}'),
                  ),
                ),
                if (state.isLoading && state.houses.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    sliver: SkeletonHouseList(),
                  )
                else if (state.houses.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _SearchEmptyView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
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
                          onTap:
                              !house.isRentLocked ||
                                  house.activeOrderBelongsToMe
                              ? () => _openDetail(house)
                              : null,
                        );
                      },
                    ),
                  ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRegionSheet() async {
    final city = ref.read(userLocationProvider).city;
    if (city.isEmpty) {
      AppToast.show(context, '请先定位或选择城市');
      return;
    }
    late final List<HouseFilterOption> districts;
    try {
      districts = await ref.read(houseDistrictsProvider(city).future);
    } on Object {
      if (mounted) AppToast.show(context, '区域加载失败，请稍后重试');
      return;
    }
    if (!mounted) return;
    final options = <String, String>{'': '不限'};
    for (final district in districts) {
      options[district.value] = district.label;
    }
    final selected = await showRegionSheet(
      context,
      selectedValue: ref.read(houseSearchProvider).region,
      options: options,
    );
    if (selected == null || !mounted) return;
    ref.read(houseSearchProvider.notifier).updateRegion(selected);
  }

  Future<void> _showRentSheet() async {
    final state = ref.read(houseSearchProvider);
    final result = await showRentSheet(
      context,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
    );
    if (result == null || !mounted) return;
    ref
        .read(houseSearchProvider.notifier)
        .updatePriceRange(
          result.start.round(),
          result.end >= 1000000 ? 0 : result.end.round(),
        );
  }

  Future<void> _showRoomSheet() async {
    late final List<HouseFilterOption> roomTypes;
    try {
      roomTypes = await ref.read(houseRoomTypesProvider.future);
    } on Object {
      if (mounted) AppToast.show(context, '户型加载失败，请稍后重试');
      return;
    }
    if (!mounted) return;
    final options = <String, String>{'': '不限'};
    for (final roomType in roomTypes) {
      options[roomType.value] = roomType.label;
    }
    final selected = await showRoomSheet(
      context,
      selectedValue: ref.read(houseSearchProvider).roomType,
      options: options,
    );
    if (selected == null || !mounted) return;
    ref.read(houseSearchProvider.notifier).updateRoomType(selected);
  }

  Future<void> _showSortSheet() async {
    final current = ref.read(houseSearchProvider);
    final sort = await showHouseSortSheet(context, selectedValue: current.sort);
    if (sort == null || !mounted) return;
    ref
        .read(houseSearchProvider.notifier)
        .updateExtraFilters(
          sort: sort,
          decoration: current.decoration,
          orientation: current.orientation,
          rentMode: current.rentMode,
          rentType: current.category,
          facilityIds: current.facilityIds,
          tagIds: current.activeTags,
        );
  }

  Future<void> _showMoreSheet() async {
    final state = ref.read(houseSearchProvider);
    late final List<dynamic> dictionaries;
    try {
      dictionaries = await Future.wait([
        ref.read(houseFacilitiesProvider.future),
        ref.read(houseTagsProvider.future),
      ]);
    } on Object {
      if (mounted) AppToast.show(context, '筛选选项加载失败，请稍后重试');
      return;
    }
    if (!mounted) return;
    final result = await showMoreFilterSheet(
      context,
      sort: state.sort,
      decoration: state.decoration,
      orientation: state.orientation,
      rentMode: state.rentMode,
      rentType: state.category,
      facilityIds: state.facilityIds,
      tagIds: state.activeTags,
      facilities: dictionaries[0],
      tags: dictionaries[1],
    );
    if (result == null || !mounted) return;
    ref
        .read(houseSearchProvider.notifier)
        .updateExtraFilters(
          sort: result.sort,
          decoration: result.decoration,
          orientation: result.orientation,
          rentMode: result.rentMode,
          rentType: result.rentType,
          facilityIds: result.facilityIds,
          tagIds: result.tagIds,
        );
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
      // 刷新时保留当前列表，避免收藏后搜索结果瞬间清空。
      await ref.read(houseSearchProvider.notifier).refresh();
    } on Object {
      if (mounted) {
        AppToast.show(context, '操作失败，请稍后重试', type: AppToastType.error);
      }
    }
  }

  void _openSearchPage() => _goBack();

  void _openDetail(House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      ref.read(houseSearchProvider.notifier).reset();
      context.goNamed(RouteNames.houseSearch);
    }
  }
}

class _SearchEmptyView extends StatelessWidget {
  const _SearchEmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 52),
          SizedBox(height: AppSpacing.md),
          Text('暂无符合条件的房源'),
          SizedBox(height: AppSpacing.sm),
          Text(
            '试试调整关键词或筛选条件',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
