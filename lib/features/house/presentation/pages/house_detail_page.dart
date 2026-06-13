import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/app/theme/app_icon.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/house.dart';
import '../../service/house_service.dart';

class HouseDetailPage extends StatefulWidget {
  const HouseDetailPage({required this.houseId, super.key});

  final String houseId;

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  final _service = HouseService();
  House? _house;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final house = await _service.getHouseDetail(widget.houseId);
      if (!mounted) return;
      setState(() => _house = house);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _DetailErrorView(message: _error!, onRetry: _load),
      );
    }

    if (_house == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _DetailSkeleton(),
      );
    }

    final house = _house!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _DetailAppBar(house: house),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -26),
                  child: _DetailContent(house: house),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(house: house),
          ),
        ],
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: CircleAvatar(
          backgroundColor: AppColors.surface,
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.goNamed(RouteNames.search);
            },
            icon: AppIcon.iconBack,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: CircleAvatar(
            backgroundColor: AppColors.surface,
            child: IconButton(
              onPressed: () => _showMessage(context, '分享功能暂未接入'),
              icon: AppIcon.iconNormal(Icons.share_outlined),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: CircleAvatar(
            backgroundColor: AppColors.surface,
            child: IconButton(
              onPressed: () => _showMessage(context, '收藏状态已模拟更新'),
              icon: Icon(
                house.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: house.isFavorite
                    ? AppColors.error
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _ImageCarousel(images: house.images),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images});

  final List<String> images;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return Container(
        color: const Color(0xFFF3E7D8),
        child: const Center(
          child: Icon(
            Icons.apartment_rounded,
            color: Color(0xFF9CA3AF),
            size: 42,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          onPageChanged: (i) => setState(() => _current = i),
          itemCount: images.length,
          itemBuilder: (context, index) => Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // debugPrint('_ImageCarouselState load error: $error');
              // debugPrint('_ImageCarouselState stackTrace: $stackTrace');
              return Container(
                color: const Color(0xFFF3E7D8),
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Color(0xFF9CA3AF),
                    size: 42,
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _current
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg_2),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            house.title,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text.rich(
                            TextSpan(
                              text: '¥ ${house.price}',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontSize: 24,
                              ),
                              children: [
                                TextSpan(
                                  text: ' /月',
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        right: 0,
                        child: Chip(
                          avatar: const Icon(
                            Icons.verified_user,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            '平台验真',
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.primaryLight,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.iconMuted,
                size: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${house.location} · ${house.community}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.iconMuted,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: house.tags.map((tag) => _DetailTag(tag)).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(
            title: '房屋信息',
            children: [
              _InfoMetric(
                icon: Icons.home_outlined,
                value: house.roomType,
                label: '户型',
              ),
              _InfoMetric(
                icon: Icons.straighten,
                value: '${house.area}m²',
                label: '面积',
              ),
              _InfoMetric(
                icon: Icons.apartment,
                value: house.floor,
                label: '楼层',
              ),
              _InfoMetric(
                icon: Icons.explore_outlined,
                value: house.orientation,
                label: '朝向',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _FacilitiesCard(house: house),
          const SizedBox(height: AppSpacing.sm),
          _LandlordCard(house: house),
          const SizedBox(height: AppSpacing.sm),
          _SmartLifeCard(house: house),
          const SizedBox(height: AppSpacing.sm),
          _DescriptionCard(house: house),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.housedetailtoolTitle),
          const SizedBox(height: AppSpacing.lg),
          Row(children: children),
        ],
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.housedetailtoolL1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.housedetailtoolL2),
        ],
      ),
    );
  }
}

class _FacilitiesCard extends StatelessWidget {
  const _FacilitiesCard({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.bathtub,
      Icons.ac_unit,
      Icons.local_laundry_service,
      Icons.water_drop,
      Icons.kitchen,
      Icons.wifi,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('房屋设施', style: AppTextStyles.housedetailtoolTitle),
              const Spacer(),
              Text(
                '查看全部',
                style: TextStyle(color: AppColors.primary, fontSize: 10),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.iconMuted,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (
                var index = 0;
                index < house.facilities.take(6).length;
                index++
              )
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        icons[index],
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        house.facilities[index],
                        style: AppTextStyles.housedetailtoolL2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandlordCard extends StatelessWidget {
  const _LandlordCard({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: house.avatarUrl.isNotEmpty
                ? NetworkImage(house.avatarUrl)
                : null,
            child: house.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: AppColors.primary, size: 24)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${house.landlordName} · 房东',
                      style: AppTextStyles.housedetailtoolTitle,
                    ),
                    if (house.isVerified) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Chip(
                        label: Text('已实名'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primaryLight,
                        side: BorderSide.none,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  '${house.responseDescription}   评分 ${house.rating} · 已租 ${house.rentedCount} 套',
                  style: AppTextStyles.housedetailtoolL2,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showTodo(context),
            icon: const Icon(
              Icons.chat_bubble,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => _showTodo(context),
            icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  void _showTodo(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('联系能力暂未接入')));
  }
}

class _SmartLifeCard extends StatelessWidget {
  const _SmartLifeCard({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 24, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('智能生活', style: AppTextStyles.housedetailtoolTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  house.isSmartLockSupported ? '智能门锁已连接，门锁运行正常' : '该房源暂不支持智能门锁',
                  style: AppTextStyles.housedetailtoolL2,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconMuted, size: 14),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('房源描述', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Text(house.description, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.house});

  final House house;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showMessage(context, '收藏状态已模拟更新'),
              icon: Icon(
                house.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: house.isFavorite ? AppColors.error : AppColors.primary,
              ),
            ),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showMessage(context, '预约看房暂未接入'),
                child: const Text('预约看房'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showMessage(context, '立即租住暂未接入'),
                child: const Text('立即租住'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: AppColors.border),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xxl),
                      topRight: Radius.circular(AppRadius.xxl),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 200, height: 30),
                      const SizedBox(height: AppSpacing.sm),
                      _SkeletonBox(width: 150, height: 34),
                      const SizedBox(height: AppSpacing.md),
                      _SkeletonBox(width: 250, height: 16),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: List.generate(
                          3,
                          (_) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: _SkeletonBox(width: 64, height: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SkeletonBox(width: 80, height: 18),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: List.generate(
                          4,
                          (_) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Column(
                                children: [
                                  _SkeletonBox(width: 34, height: 34),
                                  const SizedBox(height: AppSpacing.sm),
                                  _SkeletonBox(width: 40, height: 14),
                                  const SizedBox(height: AppSpacing.xs),
                                  _SkeletonBox(width: 30, height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SkeletonBox(width: double.infinity, height: 140),
                      const SizedBox(height: AppSpacing.md),
                      _SkeletonBox(width: double.infinity, height: 80),
                      const SizedBox(height: AppSpacing.md),
                      _SkeletonBox(width: double.infinity, height: 70),
                      const SizedBox(height: AppSpacing.md),
                      _SkeletonBox(width: double.infinity, height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x14000000),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _SkeletonBox(width: 40, height: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _SkeletonBox(height: 40)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _SkeletonBox(height: 40)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.message, required this.onRetry});

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
