import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../house/data/models/house.dart';
import '../../../house/data/providers/house_providers.dart';
import '../../../house/presentation/widgets/house_card.dart';
import '../../data/models/home_data.dart';
import '../../data/providers/home_providers.dart';
import '../widgets/home_category_tabs_delegate.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_service_entry.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _selectedTabKey;

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: homeAsync.when(
          loading: () => const _HomeSkeleton(),
          error: (error, _) => _HomeErrorView(
            message: '首页数据加载异常：$error',
            onRetry: () => ref.invalidate(homeDataProvider),
          ),
          data: (result) {
            if (result is ApiFailure<HomeData>) {
              return _HomeErrorView(
                message: result.message,
                onRetry: () => ref.invalidate(homeDataProvider),
              );
            }
            if (result is ApiSuccess<HomeData>) {
              return _buildContent(result.data);
            }
            return _HomeErrorView(
              message: '首页数据加载失败',
              onRetry: () => ref.invalidate(homeDataProvider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(HomeData data) {
    final tabs = data.tabs.where((t) => t.enabled).toList();
    if (_selectedTabKey == null || !tabs.any((t) => t.key == _selectedTabKey)) {
      _selectedTabKey = tabs.isNotEmpty ? tabs.first.key : '';
    }
    final selectedKey = _selectedTabKey!;
    final houseGroup = data.houseGroups[selectedKey];
    final locallyRentedHouseIds = ref.watch(locallyRentedHouseIdsProvider);
    final visibleItems = houseGroup?.items
        .where(
          (item) =>
              item.house == null ||
              !locallyRentedHouseIds.contains(item.house!.id),
        )
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
            AppSpacing.pageHorizontal,
            0,
          ),
          child: Column(
            children: [
              _HomeHeader(data: data.header),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: HomeSearchBar(
                    hintText: data.header.searchPlaceholder,
                    onTap: () => context.goNamed(RouteNames.search),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeDataProvider);
              await ref.read(homeDataProvider.future);
            },
            child: CustomScrollView(
              key: const PageStorageKey('home-scroll-view'),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.xs,
                    AppSpacing.pageHorizontal,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _DynamicServices(
                      entries: data.serviceEntries
                          .where((e) => e.enabled)
                          .toList(),
                      onTap: _handleServiceTap,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeCategoryTabsDelegate(
                    height: _DynamicTabs.preferredHeight(context, tabs),
                    child: _DynamicTabs(
                      tabs: tabs,
                      selectedKey: selectedKey,
                      onSelected: (key) =>
                          setState(() => _selectedTabKey = key),
                    ),
                  ),
                ),
                if (houseGroup != null)
                  _HomeContent(
                    key: PageStorageKey(selectedKey),
                    items: visibleItems ?? const <HomeFeedItem>[],
                    onHouseTap: _openDetail,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleServiceTap(ServiceEntry entry) {
    switch (entry.targetValue) {
      case 'lease':
        context.pushNamed(RouteNames.lease);
      case 'unlock_records':
        context.pushNamed(RouteNames.unlockRecords);
      case 'repairs':
        context.pushNamed(RouteNames.repairs);
      case 'customer_service':
        context.pushNamed(RouteNames.customerService);
      default:
        if (entry.targetType == 'route') {
          context.pushNamed(RouteNames.home);
        }
    }
  }

  void _openDetail(House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.data});

  final HomeHeaderData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _HeaderBuilding(),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLogo(cityName: data.cityName),
                const Spacer(),
                Text(
                  data.greeting,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBuilding extends StatelessWidget {
  const _HeaderBuilding();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -20,
      right: -40,
      width: 300,
      height: 200,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Image.asset(
            'assets/home_bk.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}

class _DynamicTabs extends StatelessWidget {
  const _DynamicTabs({
    required this.tabs,
    required this.selectedKey,
    required this.onSelected,
  });

  static const _tabPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );

  final List<HomeTab> tabs;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  static double preferredHeight(BuildContext context, List<HomeTab> tabs) {
    final style = AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700);
    final textMaxWidth =
        (MediaQuery.sizeOf(context).width -
                AppSpacing.xl * 2 -
                _tabPadding.horizontal)
            .clamp(0.0, double.infinity);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    final maxTextHeight =
        (tabs.isEmpty ? const ['Tab'] : tabs.map((t) => t.title))
            .map((title) {
              final painter = TextPainter(
                text: TextSpan(text: title, style: style),
                textDirection: textDirection,
                textScaler: textScaler,
              )..layout(maxWidth: textMaxWidth);
              return painter.height;
            })
            .fold<double>(0, (height, itemHeight) {
              return itemHeight > height ? itemHeight : height;
            });

    return (maxTextHeight + _tabPadding.vertical + 1).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (final tab in tabs)
            _DynamicTab(
              key: ValueKey('home-tab-${tab.key}'),
              tab: tab,
              isSelected: selectedKey == tab.key,
              onTap: () => onSelected(tab.key),
            ),
        ],
      ),
    );
  }
}

class _DynamicTab extends StatelessWidget {
  const _DynamicTab({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final HomeTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: _DynamicTabs._tabPadding,
          // decoration: BoxDecoration(
          //   // color: isSelected ? AppColors.primaryLight : Colors.transparent,
          //   borderRadius: BorderRadius.circular(AppRadius.lg),
          // ),
          child: Text(
            tab.title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicServices extends StatelessWidget {
  const _DynamicServices({required this.entries, required this.onTap});

  final List<ServiceEntry> entries;
  final ValueChanged<ServiceEntry> onTap;

  static const _iconMap = {
    'lease': Icons.description_rounded,
    'lock': Icons.history_rounded,
    'repair': Icons.home_repair_service_rounded,
    'service': Icons.support_agent_rounded,
  };

  static const _colorMap = {
    'lease': AppColors.primary,
    'lock': AppColors.secondary,
    'repair': AppColors.warning,
    'service': Color(0xFF7667F8),
  };

  IconData _iconFor(String iconKey) =>
      _iconMap[iconKey] ?? Icons.widgets_rounded;

  Color _colorFor(String iconKey) => _colorMap[iconKey] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 2, top: 2, right: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final entry in entries.take(4))
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry != entries.take(4).last ? AppSpacing.sm : 0,
                    ),
                    child: HomeServiceEntry(
                      icon: _iconFor(entry.iconKey),
                      label: entry.title,
                      color: _colorFor(entry.iconKey),
                      onTap: () => onTap(entry),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.items,
    required this.onHouseTap,
    super.key,
  });

  final List<HomeFeedItem> items;
  final ValueChanged<House> onHouseTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
      ),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.type == 'house' && item.house != null) {
            return HouseCard(
              house: item.house!.toHouse(),
              compact: true,
              onTap: () => onHouseTap(item.house!.toHouse()),
            );
          } else if (item.type == 'advertisement' &&
              item.advertisement != null) {
            return _FeedAdCard(ad: item.advertisement!);
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class _FeedAdCard extends StatelessWidget {
  const _FeedAdCard({required this.ad});

  final HomeAdItem ad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF367BF5), Color(0xFF75A7FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D367BF5),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '精选推荐',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.surface,
            size: 38,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            ad.title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ad.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.surface.withValues(alpha: 0.88),
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '查看详情',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.surface,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();

  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _shimmer(Color base) {
    return Color.lerp(
      base,
      base == AppColors.border ? const Color(0xFFF3F4F6) : AppColors.border,
      _controller.value,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            // Header skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: SizedBox(
                height: 170,
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: -40,
                      width: 550,
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: Container(color: _shimmer(AppColors.border)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _shimmer(AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 80,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _shimmer(AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 220,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _shimmer(AppColors.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: 180,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _shimmer(AppColors.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Search bar skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 360,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _shimmer(AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Content skeleton
            Expanded(
              child: CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  // Services skeleton
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.xs,
                      AppSpacing.pageHorizontal,
                      AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _shimmer(AppColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: List.generate(
                                4,
                                (_) => Expanded(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _shimmer(AppColors.border),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        width: 48,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _shimmer(AppColors.border),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tabs skeleton
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: HomeCategoryTabsDelegate(
                      height: 60,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: List.generate(
                            4,
                            (_) => Expanded(
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _shimmer(AppColors.border),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Cards skeleton
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.xl,
                      AppSpacing.pageHorizontal,
                      AppSpacing.xl,
                    ),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childCount: 4,
                      itemBuilder: (context, index) {
                        final heights = [180.0, 220.0, 200.0, 240.0];
                        return Container(
                          height: heights[index],
                          decoration: BoxDecoration(
                            color: _shimmer(AppColors.border),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
