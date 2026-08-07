import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
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
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          const _HeaderBuilding(),
          SafeArea(
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
        ],
      ),
    );
  }

  Widget _buildContent(HomeData data) {
    final tabs = data.tabs
        .where(
          (t) => t.enabled && t.key != 'homestay' && t.title != '\u6c11\u5bbf',
        )
        .toList();
    if (_selectedTabKey == null || !tabs.any((t) => t.key == _selectedTabKey)) {
      _selectedTabKey = tabs.isNotEmpty ? tabs.first.key : '';
    }
    final selectedKey = _selectedTabKey!;
    final isRecommendationTab = tabs.any(
      (tab) =>
          tab.key == selectedKey &&
          (tab.key == 'recommend' || tab.title == '推荐'),
    );
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
        const _HomeHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg_2,
            AppSpacing.pageHorizontal,
            AppSpacing.md,
          ),
          child: HomeSearchBar(
            hintText: '搜索小区、地址或房源',
            onTap: () => context.goNamed(RouteNames.search),
          ),
        ),
        _DynamicTabs(
          tabs: tabs,
          selectedKey: selectedKey,
          onSelected: (key) => setState(() => _selectedTabKey = key),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) =>
                _handleTabSwipe(details, tabs, selectedKey),
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeDataProvider);
                await ref.read(homeDataProvider.future);
              },
              child: CustomScrollView(
                key: const PageStorageKey('home-scroll-view'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (isRecommendationTab)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.xs,
                        AppSpacing.pageHorizontal,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            const _DynamicServices(),
                            const SizedBox(height: AppSpacing.lg),
                            const _HomeRecommendationBanner(),
                            const SizedBox(height: AppSpacing.lg),
                            _HomeSectionHeader(title: '为你推荐'),
                            const SizedBox(height: AppSpacing.sm),
                          ],
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
        ),
      ],
    );
  }

  void _handleTabSwipe(
    DragEndDetails details,
    List<HomeTab> tabs,
    String selectedKey,
  ) {
    final selectedIndex = tabs.indexWhere((tab) => tab.key == selectedKey);
    if (selectedIndex < 0 || tabs.length < 2) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200 && selectedIndex < tabs.length - 1) {
      setState(() => _selectedTabKey = tabs[selectedIndex + 1].key);
    } else if (velocity > 200 && selectedIndex > 0) {
      setState(() => _selectedTabKey = tabs[selectedIndex - 1].key);
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
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const _HomeBrandLogo()]),
                ],
              ),
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
      top: 0,
      left: 0,
      right: 0,
      height: 214,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0, 0.58, 1],
                ).createShader(bounds),
                child: Image.asset(
                  'assets/home/home_bk.png',
                  fit: BoxFit.fill,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            top: 32,
            child: IgnorePointer(
              child: Image.asset(
                'assets/home/Slogan.png',
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF4FF), Color(0xFFF4F9FF), Color(0xFFFBFDFF)],
          stops: [0, 0.42, 1],
        ),
      ),
    );
  }
}

class _HomeBrandLogo extends StatelessWidget {
  const _HomeBrandLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo/logo.png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '勿忧管家',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '租房无忧·生活有光',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _CitySelector extends StatelessWidget {
  const _CitySelector({required this.cityName});

  final String cityName;

  @override
  Widget build(BuildContext context) {
    /* final items = [
      (
        HugeIcons.strokeRoundedShield01,
        '品质房源',
        '严格审核',
        AppColors.textPrimary,
      ),
      (
        HugeIcons.strokeRoundedCircleDollar,
        '透明价格',
        '无中介费',
        AppColors.textPrimary,
      ),
      (
        HugeIcons.strokeRoundedHome01,
        '安心入住',
        '专业保障',
        AppColors.textPrimary,
      ),
      (
        HugeIcons.strokeRoundedCustomerService01,
        '贴心服务',
        '7×24小时',
        Color(0xFF7667F8),
      ),
    ]; */

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            color: AppColors.textPrimary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            cityName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  static const _tabPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    4,
    AppSpacing.lg,
    AppSpacing.sm,
  );

  final List<HomeTab> tabs;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  // ignore: unused_element
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
    final selectedIndex = tabs.indexWhere((tab) => tab.key == selectedKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (selectedIndex < 0 || tabs.length < 2) return;
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -200 && selectedIndex < tabs.length - 1) {
            onSelected(tabs[selectedIndex + 1].key);
          } else if (velocity > 200 && selectedIndex > 0) {
            onSelected(tabs[selectedIndex - 1].key);
          }
        },
        behavior: HitTestBehavior.opaque,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tab.title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: isSelected ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: isSelected ? 32 : 0,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicServices extends StatelessWidget {
  const _DynamicServices();

  static const _iconMap = {
    'lease': HugeIcons.strokeRoundedFile01,
    'lock': HugeIcons.strokeRoundedLock,
    'repair': HugeIcons.strokeRoundedRepair,
    'service': HugeIcons.strokeRoundedCustomerService01,
  };

  static const _colorMap = {
    'lease': AppColors.primary,
    'lock': AppColors.secondary,
    'repair': AppColors.warning,
    'service': Color(0xFF7667F8),
  };

  // ignore: unused_element
  List<List<dynamic>> _iconFor(String iconKey) =>
      _iconMap[iconKey] ?? HugeIcons.strokeRoundedGridView;

  // ignore: unused_element
  Color _colorFor(String iconKey) => _colorMap[iconKey] ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (HugeIcons.strokeRoundedShield01, '品质房源', '严格审核', AppColors.primary),
      (
        HugeIcons.strokeRoundedDollarCircle,
        '透明价格',
        '无中介费',
        AppColors.secondary,
      ),
      (HugeIcons.strokeRoundedHome01, '安心入住', '专业保障', AppColors.warning),
      (
        HugeIcons.strokeRoundedCustomerService01,
        '贴心服务',
        '7×24小时',
        AppColors.textPrimary,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
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
              for (final item in items)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: item != items.last ? AppSpacing.sm : 0,
                    ),
                    child: HomeServiceEntry(
                      icon: item.$1,
                      label: item.$2,
                      subtitle: item.$3,
                      color: item.$4,
                      forceMonochrome: true,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _subtitleFor(String iconKey) => switch (iconKey) {
    'lease' => '严格审核',
    'lock' => '透明价格',
    'repair' => '安心入住',
    'service' => '7×24小时',
    _ => '品质服务',
  };
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
      ],
    );
  }
}

class _HomeRecommendationBanner extends StatelessWidget {
  const _HomeRecommendationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primarySoft.withValues(alpha: 0.94),
            AppColors.primaryLight.withValues(alpha: 0.94),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145B8FD8),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: AppSpacing.lg,
            top: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Text(
                '勿忧精选',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            top: 38,
            child: Text(
              '精选好房 · 为你优选',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.md,
            child: Text(
              '从位置、品质到服务，精选细选只为更好的你',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const Positioned(
            right: AppSpacing.lg,
            top: 34,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.primary,
                size: 22,
              ),
            ),
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
        itemBuilder: (context, index) => _buildItem(items[index]),
      ),
    );
  }

  Widget _buildItem(HomeFeedItem item) {
    if (item.type == 'house' && item.house != null) {
      final house = item.house!.toHouse();
      return HouseCard(
        house: house,
        compact: true,
        onTap: () => onHouseTap(house),
      );
    }
    if (item.type == 'advertisement' && item.advertisement != null) {
      return _FeedAdCard(ad: item.advertisement!);
    }
    return const SizedBox.shrink();
  }
}

class _FeedAdCard extends StatelessWidget {
  const _FeedAdCard({required this.ad});

  final HomeAdItem ad;

  String get _targetType => ad.targetType.trim().toLowerCase();

  bool get _canNavigate =>
      ad.targetValue.trim().isNotEmpty &&
      const {'house', 'house_list', 'url'}.contains(_targetType);

  String? get _actionLabel => switch (_targetType) {
    'house' => '查看房源',
    'house_list' => '查看相关房源',
    'url' => '了解详情',
    _ => null,
  };

  Future<void> _handleTap(BuildContext context) async {
    if (!_canNavigate) return;
    final target = ad.targetValue.trim();
    switch (_targetType) {
      case 'house':
        await context.pushNamed(
          RouteNames.houseDetail,
          pathParameters: {'houseId': target},
        );
      case 'house_list':
        await context.pushNamed(
          RouteNames.houseSearchResult,
          queryParameters: {'keyword': target},
        );
      case 'url':
        final uri = Uri.tryParse(target);
        final opened =
            uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('暂时无法打开该链接')));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionLabel = _canNavigate ? _actionLabel : null;
    final hasImage = ad.imageUrl.trim().isNotEmpty;
    final card = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF367BF5), Color(0xFF75A7FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.35,
                  child: Image.network(
                    ad.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _AdImageFallback(),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _AdBadge(
                    backgroundColor: Colors.black.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasImage) ...[
                  const _AdBadge(),
                  const SizedBox(height: AppSpacing.lg),
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedGift,
                    color: AppColors.surface,
                    size: 38,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  ad.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (ad.description.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ad.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.88),
                      height: 1.55,
                    ),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Text(
                        actionLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: AppColors.surface,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D367BF5),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _canNavigate ? () => _handleTap(context) : null,
            child: card,
          ),
        ),
      ),
    );
  }
}

class _AdBadge extends StatelessWidget {
  const _AdBadge({this.backgroundColor});

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.18),
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
    );
  }
}

class _AdImageFallback extends StatelessWidget {
  const _AdImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF5C91F4),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: AppColors.surface,
          size: 38,
        ),
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
            const HugeIcon(
              icon: HugeIcons.strokeRoundedWifiOff01,
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
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01),
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
