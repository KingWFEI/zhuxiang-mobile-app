import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../domain/entities/house.dart';
import '../providers/house_providers.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/hot_search_widget.dart';
import '../widgets/house_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/skeleton_house_list.dart';

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
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    const preloadDistance = 320.0;
    if (_scrollController.position.extentAfter < preloadDistance) {
      ref.read(houseSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(houseSearchProvider);
    final notifier = ref.read(houseSearchProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  AppSpacing.md,
                ),
                sliver: SliverList.list(
                  children: [
                    const _FindHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    HouseSearchBar(
                      keyword: state.keyword,
                      activeFilterCount: state.activeFilterCount,
                      onChanged: notifier.updateKeyword,
                      onSubmitted: notifier.selectKeyword,
                      onFilterTap: () => _showFilters(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CategorySelector(
                      selected: state.category,
                      onSelected: notifier.updateCategory,
                    ),
                    if (state.keyword.isEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SearchDiscoverySection(
                        history: state.searchHistory,
                        hotKeywords: state.hotKeywords,
                        onKeywordTap: notifier.selectKeyword,
                        onClearHistory: notifier.clearSearchHistory,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    const _RecommendBanner(),
                    const SizedBox(height: AppSpacing.sm),
                    _ResultHeader(
                      count: state.houses.length,
                      hasFilters: state.hasActiveFilters,
                      onReset: notifier.reset,
                    ),
                  ],
                ),
              ),
              if (state.isLoading && state.houses.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    120,
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
                      return KeyedSubtree(
                        key: ValueKey(house.id),
                        child: HouseCard(
                          house: house,
                          onTap: () => _openDetail(context, house),
                        ),
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
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    final current = ref.read(houseSearchProvider);
    final selection = await FilterBottomSheet.show(context, current);
    if (selection == null) return;
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

  void _openDetail(BuildContext context, House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }
}

class _FindHeader extends StatelessWidget {
  const _FindHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.home_work, color: AppColors.primary, size: 18),
        SizedBox(width: AppSpacing.sm),
        Text(
          '住享找房',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const categories = {
      '': '全部',
      'recommended': '推荐',
      'short_rent': '短租',
      'homestay': '民宿',
      'long_rent': '长租',
    };
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories.entries.elementAt(index);
          return ChoiceChip(
            label: Text(category.value),
            selected: selected == category.key,
            onSelected: (_) => onSelected(category.key),
          );
        },
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.count,
    required this.hasFilters,
    required this.onReset,
  });

  final int count;
  final bool hasFilters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('找到 $count 套房源', style: AppTextStyles.titleMedium),
        const Spacer(),
        if (hasFilters)
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('重置条件'),
          ),
      ],
    );
  }
}

class _RecommendBanner extends StatelessWidget {
  const _RecommendBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Text(
            '真实房源，多条件精准查找',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
          ),
        ],
      ),
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
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return TextButton(onPressed: onRetry, child: Text('$error，点击重试'));
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text('已经到底了')),
      );
    }
    return const SizedBox(height: AppSpacing.md);
  }
}
