import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/features/house/data/models/house.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../application/house_search_notifier.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/house_card.dart';
import '../widgets/house_filter_bar.dart';
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
  final Set<String> _selectedQuickConditions = <String>{};
  final Map<String, bool> _favoriteStates = <String, bool>{};

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
    final sortText = houseSortLabels[state.sort] ?? '综合排序';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
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
                      onFilterTap: _openFilterPage,
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
                      onRegionTap: _openFilterPage,
                      onRentTap: _openFilterPage,
                      onRoomTap: _openFilterPage,
                      onMoreTap: _openFilterPage,
                      onSortTap: _showSortSheet,
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
                    child: SearchResultQuickConditions(
                      onTap: _toggleQuickCondition,
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
                    child: HouseListHeader(
                      countText: state.houses.isEmpty ? '0' : '128',
                      sortText: sortText,
                      onSortTap: _showSortSheet,
                    ),
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
                          isFavorite:
                              _favoriteStates[house.id] ?? house.isFavorite,
                          onFavoriteTap: () => _toggleFavorite(house),
                          onTap: () => _openDetail(house),
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

  /// 打开全屏筛选页并将有效筛选同步到搜索状态。
  Future<void> _openFilterPage() async {
    final selection = await context.pushNamed<HouseFilterSelection>(
      RouteNames.houseFilter,
    );
    if (selection == null || !mounted) return;
    ref
        .read(houseSearchProvider.notifier)
        .updateFilter(
          region: selection.region,
          minPrice: selection.minPrice,
          maxPrice: selection.maxPrice,
          roomType: selection.roomType,
          sort: selection.sort,
        );
  }

  /// 更新排序状态并触发已有搜索逻辑。
  Future<void> _showSortSheet() async {
    final current = ref.read(houseSearchProvider);
    final sort = await showHouseSortSheet(context, selectedValue: current.sort);
    if (sort == null || !mounted) return;
    ref
        .read(houseSearchProvider.notifier)
        .updateFilter(
          region: current.region,
          minPrice: current.minPrice,
          maxPrice: current.maxPrice,
          roomType: current.roomType,
          sort: sort,
        );
  }

  /// 快捷条件保留本地选中态，“更多条件”进入全屏筛选页。
  void _toggleQuickCondition(String condition) {
    if (condition == '更多条件') {
      _openFilterPage();
      return;
    }
    setState(() {
      if (!_selectedQuickConditions.add(condition)) {
        _selectedQuickConditions.remove(condition);
      }
    });
    // TODO: 后续将快捷条件转换为真实接口参数。
  }

  /// 收藏只更新本地状态，后续对接收藏接口。
  void _toggleFavorite(House house) {
    setState(() {
      final current = _favoriteStates[house.id] ?? house.isFavorite;
      _favoriteStates[house.id] = !current;
    });
    // TODO: 用户登录后调用收藏/取消收藏接口。
  }

  void _openSearchPage() => context.pushNamed(RouteNames.houseSearch);

  void _openDetail(House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }

  void _goBack() {
    ref.read(houseSearchProvider.notifier).reset();
    context.goNamed(RouteNames.search);
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
