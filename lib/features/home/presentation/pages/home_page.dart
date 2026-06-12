import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../house/data/datasources/mock_house_datasource.dart';
import '../../../house/domain/entities/house.dart';
import '../../../house/presentation/widgets/house_card.dart';
import '../widgets/home_category_tabs_delegate.dart';
import '../widgets/home_convenient_services.dart';
import '../widgets/home_search_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  HomeCategory _selectedCategory = HomeCategory.recommended;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final houses = MockHouseDatasource.houses;
    final selectedHouses = _housesFor(_selectedCategory, houses);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: Column(
                children: [
                  _HomeHeader(name: user?.nickname ?? '陌生游客'),
                  const SizedBox(height: AppSpacing.xl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 360,
                      child: HomeSearchBar(
                        hintText: '搜索小区、地址或房源',
                        onTap: () => context.goNamed(RouteNames.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                key: const PageStorageKey('home-scroll-view'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xs,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: HomeConvenientServices(
                        onLeaseTap: () => context.pushNamed(RouteNames.lease),
                        onDoorRecordTap: _showDoorRecordTodo,
                        onRepairTap: () => context.pushNamed(RouteNames.repair),
                        onCustomerServiceTap: () =>
                            context.pushNamed(RouteNames.customerService),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: HomeCategoryTabsDelegate(
                      height: HomeCategoryTabs.height,
                      child: HomeCategoryTabs(
                        selectedCategory: _selectedCategory,
                        onSelected: _selectCategory,
                      ),
                    ),
                  ),
                  HomeCategoryContent(
                    key: PageStorageKey(_selectedCategory.name),
                    category: _selectedCategory,
                    houses: selectedHouses,
                    onHouseTap: _openDetail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoorRecordTodo() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('开门记录功能开发中')));
  }

  void _selectCategory(HomeCategory category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
    });
  }

  List<House> _housesFor(HomeCategory category, List<House> houses) {
    const categoryOrders = {
      HomeCategory.recommended: [0, 1, 2, 3, 4],
      HomeCategory.shortRent: [2, 0, 3, 4],
      HomeCategory.homestay: [3, 2, 0, 4],
      HomeCategory.longRent: [1, 4, 0, 3],
    };

    return [
      for (final index in categoryOrders[category]!)
        if (index < houses.length) houses[index],
    ];
  }

  void _openDetail(House house) {
    context.pushNamed(
      RouteNames.houseDetail,
      pathParameters: {'houseId': house.id},
    );
  }
}

enum HomeCategory {
  recommended('推荐', '为你精选', '品质房源，住得舒心'),
  shortRent('短租', '灵活短住', '按需入住，轻松出发'),
  homestay('民宿', '城市民宿', '发现更有温度的居住体验'),
  longRent('长租', '安心长租', '稳定生活，从理想住所开始');

  const HomeCategory(this.label, this.title, this.subtitle);

  final String label;
  final String title;
  final String subtitle;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _HeaderBuilding(),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.home_work, color: AppColors.primary, size: 34),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      '住享',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '早安， $name',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 32),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('欢迎来到你的安心居住空间', style: AppTextStyles.bodyLarge),
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
      top: 10,
      right: -40,
      width: 550,
      height: 250,
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

class HomeCategoryTabs extends StatelessWidget {
  const HomeCategoryTabs({
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  static const double height = 60;

  final HomeCategory selectedCategory;
  final ValueChanged<HomeCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final category in HomeCategory.values)
            Expanded(
              child: _CategoryTab(
                key: ValueKey('home-category-${category.name}'),
                category: category,
                isSelected: selectedCategory == category,
                onTap: () => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.category,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final HomeCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            category.label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeCategoryContent extends StatelessWidget {
  const HomeCategoryContent({
    required this.category,
    required this.houses,
    required this.onHouseTap,
    super.key,
  });

  final HomeCategory category;
  final List<House> houses;
  final ValueChanged<House> onHouseTap;

  @override
  Widget build(BuildContext context) {
    final items = _buildFeedItems();

    return SliverMainAxisGroup(
      key: key,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: _CategoryIntroduction(category: category),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final house = item.house;

              if (house != null) {
                return HouseCard(
                  house: house,
                  compact: true,
                  onTap: () => onHouseTap(house),
                );
              } else if (item.ad != null) {
                return _HomeAdCard(data: item.ad!);
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  List<_HomeFeedItem> _buildFeedItems() {
    final items = houses.map(_HomeFeedItem.house).toList();
    final ad = _adForCategory(category);

    if (ad != null) {
      items.insert(items.length > 1 ? 1 : 0, _HomeFeedItem.ad(ad));
    }

    return items;
  }

  _HomeAdData? _adForCategory(HomeCategory category) {
    return switch (category) {
      HomeCategory.recommended => const _HomeAdData(
        label: '品牌推荐',
        title: '毕业季安心租房',
        description: '品质公寓限时优惠\n签约即享专属好礼',
        icon: Icons.card_giftcard_rounded,
        colors: [Color(0xFF367BF5), Color(0xFF75A7FF)],
      ),
      HomeCategory.homestay => const _HomeAdData(
        label: '精选专题',
        title: '周末住进风景里',
        description: '发现城市周边特色民宿',
        icon: Icons.landscape_rounded,
        colors: [Color(0xFF38A88A), Color(0xFF86D4BE)],
      ),
      HomeCategory.shortRent || HomeCategory.longRent => null,
    };
  }
}

class _HomeFeedItem {
  const _HomeFeedItem.house(this.house) : ad = null;

  const _HomeFeedItem.ad(this.ad) : house = null;

  final House? house;
  final _HomeAdData? ad;
}

class _HomeAdData {
  const _HomeAdData({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });

  final String label;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
}

class _HomeAdCard extends StatelessWidget {
  const _HomeAdCard({required this.data});

  final _HomeAdData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.colors,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: data.colors.first.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
              data.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Icon(data.icon, color: AppColors.surface, size: 38),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.description,
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

class _CategoryIntroduction extends StatelessWidget {
  const _CategoryIntroduction({required this.category});

  final HomeCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.title, style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(category.subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
