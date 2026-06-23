import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/app/theme/app_icon.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/providers/house_providers.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../rental_flow/presentation/providers/rental_flow_providers.dart';

class HouseDetailPage extends ConsumerWidget {
  const HouseDetailPage({required this.houseId, super.key});

  final String houseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseDetailAsync = ref.watch(houseDetailProvider(houseId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: houseDetailAsync.when(
        data: (result) {
          if (result is ApiFailure<HouseDetail>) {
            return _DetailErrorView(
              message: result.message,
              onRetry: () {
                ref.invalidate(houseDetailProvider(houseId));
              },
            );
          }
          if (result is ApiSuccess<HouseDetail>) {
            final house = result.data;
            return Stack(
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
            );
          }

          return _DetailErrorView(
            message: '房源详情加载失败',
            onRetry: () {
              ref.invalidate(houseDetailProvider(houseId));
            },
          );
        },
        error: (error, stackTrace) {
          return _DetailErrorView(
            message: '房源详情加载异常：$error',
            onRetry: () {
              ref.invalidate(houseDetailProvider(houseId));
            },
          );
        },
        loading: () {
          return const _DetailSkeleton();
        },
      ),
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: AppColors.surface,
      leadingWidth: 44,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(
            dimension: 28,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: const CircleBorder(),
                fixedSize: const Size.square(28),
                minimumSize: const Size.square(28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed(RouteNames.search);
              },
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            iconSize: 16,
            onPressed: () => _showMessage(context, '分享功能暂未接入'),
            icon: AppIcon.iconNormal(Icons.share_outlined),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: const CircleBorder(),
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            iconSize: 16,
            onPressed: () => _showMessage(context, '收藏状态已模拟更新'),
            icon: house.isFavorite
                ? AppIcon.iconNormal(Icons.favorite, color: AppColors.error)
                : AppIcon.iconNormal(
                    Icons.favorite_border,
                    color: AppColors.textPrimary,
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

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            house.title,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text.rich(
                            TextSpan(
                              text: '¥ ${house.price}',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontSize: 18,
                              ),
                              children: [
                                TextSpan(
                                  text: ' /月',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
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

  final HouseDetail house;

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

  final HouseDetail house;

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

  final HouseDetail house;

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

  final HouseDetail house;

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

class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(rentalFlowProvider);
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: flow.isLoading
                    ? null
                    : () => _startConsultation(context, ref),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('在线咨询'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: flow.isLoading ? null : () => _openViewing(context),
                icon: const Icon(Icons.event_available_outlined, size: 18),
                label: const Text('预约看房'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: flow.isLoading
                    ? null
                    : () => _openApplication(context),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: const Text('立即申请'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startConsultation(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(rentalFlowProvider.notifier);
    if (ref.read(rentalFlowProvider).houseId != house.id) {
      await notifier.loadFlow(house.id);
    }
    final ok = await notifier.startConsultation();
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已创建咨询会话')));
    context.pushNamed(RouteNames.customerService);
  }

  void _openViewing(BuildContext context) {
    context.pushNamed(
      RouteNames.viewingAppointment,
      pathParameters: {'houseId': house.id},
      queryParameters: {'houseTitle': house.title},
    );
  }

  void _openApplication(BuildContext context) {
    context.pushNamed(
      RouteNames.rentalApplication,
      pathParameters: {'houseId': house.id},
    );
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
              expandedHeight: 150,
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
                  margin: const EdgeInsets.only(bottom: 40),
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
                      // 标题 + 价格 + 验真 chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.lg_2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SkeletonBox(width: 200, height: 20),
                                  const SizedBox(height: AppSpacing.xs),
                                  _SkeletonBox(width: 150, height: 24),
                                ],
                              ),
                            ),
                          ),
                          _SkeletonBox(width: 64, height: 24),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // 位置
                      Row(
                        children: [
                          _SkeletonBox(width: 14, height: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _SkeletonBox(height: 16)),
                          _SkeletonBox(width: 16, height: 16),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 标签
                      Row(
                        children: List.generate(
                          4,
                          (_) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: _SkeletonBox(width: 64, height: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 房屋信息
                      _SkeletonCard(
                        titleWidth: 60,
                        child: Row(
                          children: List.generate(
                            4,
                            (_) => Expanded(
                              child: Column(
                                children: [
                                  _SkeletonBox(width: 24, height: 24),
                                  const SizedBox(height: AppSpacing.xs),
                                  _SkeletonBox(width: 40, height: 14),
                                  const SizedBox(height: AppSpacing.xs),
                                  _SkeletonBox(width: 30, height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 房屋设施
                      _SkeletonCard(
                        titleWidth: 60,
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: List.generate(
                                6,
                                (_) => Expanded(
                                  child: Column(
                                    children: [
                                      _SkeletonBox(width: 24, height: 24),
                                      const SizedBox(height: AppSpacing.sm),
                                      _SkeletonBox(width: 40, height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 房东信息
                      _SkeletonCard(
                        titleWidth: 80,
                        child: Row(
                          children: [
                            const _SkeletonBox(width: 48, height: 48),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SkeletonBox(width: 120, height: 16),
                                  const SizedBox(height: 2),
                                  _SkeletonBox(width: 200, height: 12),
                                ],
                              ),
                            ),
                            _SkeletonBox(width: 40, height: 40),
                            const SizedBox(width: AppSpacing.sm),
                            _SkeletonBox(width: 40, height: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 智能生活
                      _SkeletonCard(
                        titleWidth: 80,
                        child: Row(
                          children: [
                            const _SkeletonBox(width: 24, height: 24),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SkeletonBox(width: 80, height: 16),
                                  const SizedBox(height: AppSpacing.sm),
                                  _SkeletonBox(width: 200, height: 12),
                                ],
                              ),
                            ),
                            _SkeletonBox(width: 14, height: 14),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 房源描述
                      _SkeletonCard(
                        titleWidth: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _SkeletonBox(width: double.infinity, height: 14),
                            const SizedBox(height: AppSpacing.xs),
                            _SkeletonBox(width: double.infinity, height: 14),
                            const SizedBox(height: AppSpacing.xs),
                            _SkeletonBox(width: 200, height: 14),
                          ],
                        ),
                      ),
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
                  Expanded(child: _SkeletonBox(height: 40)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonBox(height: 40)),
                  const SizedBox(width: AppSpacing.sm),
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

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.titleWidth, required this.child});

  final double titleWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: titleWidth, height: 16),
          child,
        ],
      ),
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
