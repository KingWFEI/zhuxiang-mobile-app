import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/app/theme/app_icon.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/models/immersive_tour.dart';
import 'package:zhuxiang_app/features/house/data/providers/house_providers.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../rental_flow/presentation/widgets/confirm_rent_sheet.dart';

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

class _DetailAppBar extends ConsumerWidget {
  const _DetailAppBar({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () async {
              final authState = ref.read(authControllerProvider);
              if (!authState.isLoggedIn) {
                context.pushNamed(RouteNames.login);
                return;
              }
              try {
                if (house.isFavorite) {
                  await ref.read(houseServiceProvider).removeFavorite(house.id);
                } else {
                  await ref.read(houseServiceProvider).addFavorite(house.id);
                }
                ref.invalidate(houseDetailProvider(house.id));
              } on Object {
                if (context.mounted) AppToast.show(context, '操作失败', type: AppToastType.error);
              }
            },
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

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                              text: '¥ ${_displayPrice(house.price)}',
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                size: 10,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                '平台验真',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
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
                  style: TextStyle(
                    fontSize: 10,
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
          _ImmersiveTourEntryCard(house: house),
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

String _displayPrice(int price) {
  if (price < 10000) return '$price';
  final value = price / 100;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
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
          const SizedBox(height: 6),
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
          const SizedBox(height: 2),
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
                style: TextStyle(color: AppColors.primary, fontSize: 8),
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

class _ImmersiveTourEntryCard extends ConsumerWidget {
  const _ImmersiveTourEntryCard({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(
      immersiveTourAvailabilityProvider(house.id),
    );

    return availabilityAsync.when(
      data: (result) {
        if (result is! ApiSuccess<ImmersiveTourAvailability>) {
          return const SizedBox.shrink();
        }

        final availability = result.data;
        if (!availability.available) return const SizedBox.shrink();

        final coverUrl = availability.coverImageUrl.isNotEmpty
            ? availability.coverImageUrl
            : house.coverImage;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () {
              context.pushNamed(
                RouteNames.immersiveTour,
                pathParameters: {'houseId': house.id},
              );
            },
            child: Container(
              height: 112,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.card,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl.isNotEmpty)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFF1F2937));
                      },
                    )
                  else
                    Container(color: const Color(0xFF1F2937)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.74),
                          Colors.black.withValues(alpha: 0.30),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.view_in_ar,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '沉浸式看房',
                                    style: AppTextStyles.housedetailtoolTitle
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '在线浏览房间场景和空间动线',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '立即体验',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
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
                    Expanded(
                      child: Text(
                        '${house.landlordName} · 房东',
                        style: AppTextStyles.housedetailtoolTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (house.isVerified) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        '已实名',
                        style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
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
          Text('房源描述', style: AppTextStyles.housedetailtoolTitle),
          const SizedBox(height: 4),
          Text(
            house.description,
            style: AppTextStyles.housedetailtoolTitle.copyWith(
              color: const Color.fromARGB(255, 78, 78, 78),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 9,
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
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.primary, width: 1),
                  foregroundColor: AppColors.primary,
                  fixedSize: const Size.fromHeight(36),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _openViewing(context),
                child: const Text('预约看房'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  fixedSize: const Size.fromHeight(36),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _openApplication(context, ref),
                child: Text(_applicationLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _applicationLabel {
    if (house.isRented) return '已出租';
    if (!house.isRentLocked) return '立即申请';
    return house.activeOrderBelongsToMe ? '继续办理' : '办理中';
  }

  void _openViewing(BuildContext context) {
    context.pushNamed(
      RouteNames.viewingAppointment,
      pathParameters: {'houseId': house.id},
      queryParameters: {'houseTitle': house.title},
    );
  }

  void _openApplication(BuildContext context, WidgetRef ref) {
    if (house.isRented) {
      _showRentedDialog(context);
      return;
    }
    if (house.isRentLocked) {
      if (house.activeOrderBelongsToMe) {
        _showMyActiveOrderDialog(context);
      } else {
        _showLockedDialog(context);
      }
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (!authState.isLoggedIn) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('请先登录')));
      context.pushNamed(RouteNames.login);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmRentSheet(house: house),
    );
  }

  Future<void> _showMyActiveOrderDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('你有未完成订单'),
        content: const Text('你已为该房源创建租赁订单，可继续完成实名认证、合同确认、支付或签约流程。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: const Text('继续办理'),
          ),
        ],
      ),
    );
    if (action == 'continue' && context.mounted) {
      context.pushNamed(RouteNames.rentOrders);
    }
  }

  Future<void> _showLockedDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('房源办理中'),
        content: const Text('该房源已有租客提交租赁订单，暂时无法发起新的租赁申请。你可以先收藏房源，若订单取消后可继续办理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'search'),
            child: const Text('查看更多房源'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'ok'),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
    if (action == 'search' && context.mounted) {
      context.goNamed(RouteNames.search);
    }
  }

  Future<void> _showRentedDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('房源已出租'),
        content: const Text('该房源已经完成签约，暂时无法发起新的租赁申请。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我知道了'),
          ),
        ],
      ),
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
