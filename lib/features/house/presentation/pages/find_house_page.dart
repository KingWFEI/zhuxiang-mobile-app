import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../home/presentation/widgets/home_search_bar.dart';
import '../../domain/entities/house.dart';
import '../../data/providers/house_providers.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/house_card.dart';
import '../widgets/house_filter_bar.dart';
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
  final Set<String> _selectedQuickTags = <String>{};
  final Map<String, bool> _favoriteStates = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
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
    final sortText = houseSortLabels[state.sort] ?? '综合排序';

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HouseLocationHeader(
                        city: '重庆',
                        district: '渝北区',
                        onMapTap: _showMapPlaceholder,
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
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    0,
                  ),
                  child: HouseFilterBar(
                    onRegionTap: _showFilters,
                    onRentTap: _showFilters,
                    onRoomTap: _showFilters,
                    onMoreTap: _showFilters,
                    onSortTap: _showSortSheet,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    5,
                    AppSpacing.xl,
                    0,
                  ),
                  child: HouseQuickTags(
                    selectedTags: _selectedQuickTags,
                    onTagTap: _toggleQuickTag,
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
                    countText: '1286',
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

  /// 地图找房尚未接入，先提供明确点击反馈。
  void _showMapPlaceholder() {
    // TODO: 接入地图 SDK 后跳转地图找房页面。
    _showMessage('地图找房功能待接入');
  }

  /// 打开全屏筛选页并同步有效筛选字段。
  Future<void> _showFilters() async {
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

  Future<void> _showSortSheet() async {
    final selected = await showHouseSortSheet(
      context,
      selectedValue: ref.read(houseSearchProvider).sort,
    );
    if (selected == null || !mounted) return;
    final current = ref.read(houseSearchProvider);
    ref
        .read(houseSearchProvider.notifier)
        .updateFilter(
          region: current.region,
          minPrice: current.minPrice,
          maxPrice: current.maxPrice,
          roomType: current.roomType,
          sort: selected,
        );
  }

  /// 快捷标签当前只维护本地选中态，后续可映射为真实接口参数。
  void _toggleQuickTag(String tag) {
    setState(() {
      if (!_selectedQuickTags.add(tag)) _selectedQuickTags.remove(tag);
    });
    // TODO: 后续将快捷标签转换为后端筛选参数并刷新列表。
  }

  /// 收藏状态仅在本页本地切换，后续再接收藏接口。
  void _toggleFavorite(House house) {
    setState(() {
      final current = _favoriteStates[house.id] ?? house.isFavorite;
      _favoriteStates[house.id] = !current;
    });
    // TODO: 用户登录后调用收藏/取消收藏接口。
  }

  /// 复用项目已有房源详情路由。
  void _openDetail(House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
