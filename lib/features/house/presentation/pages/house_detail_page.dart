import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zhuxiang_app/app/theme/app_icon.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/models/house_facility_item.dart';
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
import '../../../landlord/data/models/landlord_profile.dart';
import '../../../real_name_auth/data/models/real_name_auth_models.dart';
import '../../../real_name_auth/data/providers/real_name_auth_providers.dart';
import '../../../rental_flow/presentation/widgets/confirm_rent_sheet.dart';

class HouseDetailPage extends ConsumerWidget {
  const HouseDetailPage({required this.houseId, super.key});

  final String houseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseDetailAsync = ref.watch(houseDetailProvider(houseId));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 250,
                            child: _ImageCarousel(
                              images: house.images.isEmpty
                                  ? [house.coverImage]
                                  : house.images,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -38),
                            child: _DetailContent(house: house),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _DetailHeaderActions(house: house),
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

class _DetailHeaderActions extends ConsumerWidget {
  const _DetailHeaderActions({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          _HeaderCircleButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.goNamed(RouteNames.search);
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          const Spacer(),
          _HeaderCircleButton(
            onPressed: () => _showMessage(context, '分享功能暂未接入'),
            icon: AppIcon.iconNormal(Icons.share_outlined),
          ),
          const SizedBox(width: AppSpacing.sm),
          _HeaderCircleButton(
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
                if (context.mounted) {
                  AppToast.show(context, '操作失败', type: AppToastType.error);
                }
              }
            },
            icon: house.isFavorite
                ? AppIcon.iconNormal(Icons.favorite, color: AppColors.error)
                : AppIcon.iconNormal(
                    Icons.favorite_border,
                    color: AppColors.textPrimary,
                  ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        iconSize: 19,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          fixedSize: const Size.square(40),
          minimumSize: const Size.square(40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
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
    final images = widget.images.where((image) => image.isNotEmpty).toList();

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
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x52000000), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 42,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_current + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: IgnorePointer(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroInfoCard(house: house),
          const SizedBox(height: AppSpacing.md),
          _FacilitiesCard(house: house),
          const SizedBox(height: AppSpacing.md),
          _ImmersiveTourEntryCard(house: house),
          _LandlordCard(house: house),
          const SizedBox(height: AppSpacing.md),
          _SmartLifeCard(house: house),
          const SizedBox(height: AppSpacing.md),
          _DescriptionCard(house: house),
        ],
      ),
    );
  }
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    final tags = [if (house.rentType.isNotEmpty) house.rentType, ...house.tags];
    return Container(
      key: const Key('house-detail-floating-info-card'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1D4F91),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  house.title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    // letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _DetailSourceBadge(
                label: house.sourceLabel,
                isPlatform: house.isPlatformSource,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LocationRow(house: house),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: tags.take(6).map((tag) => _DetailTag(tag)).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                _displayPrice(house.price),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 28,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 3),
                child: Text(
                  '/月',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (house.paymentMethod.isNotEmpty)
                Text(
                  house.paymentMethod,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(height: 1, color: Color(0xFFEEF1F5)),
          ),
          Row(
            children: [
              _InfoMetric(value: house.roomType, label: '户型'),
              _MetricDivider(),
              _InfoMetric(value: '${house.area}m²', label: '面积'),
              _MetricDivider(),
              _InfoMetric(value: house.floor, label: '楼层'),
              _MetricDivider(),
              _InfoMetric(value: house.orientation, label: '朝向'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    final canOpenMap = house.longitude != null && house.latitude != null;
    return InkWell(
      onTap: canOpenMap
          ? () => context.pushNamed(
              RouteNames.houseMap,
              pathParameters: {'houseId': house.id},
              extra: {
                'latitude': house.latitude,
                'longitude': house.longitude,
                'houseTitle': house.title,
                'houseAddress': '${house.location} · ${house.community}',
              },
            )
          : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${house.location} · ${house.community}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (canOpenMap)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
        ],
      ),
    );
  }
}

String _displayPrice(int price) {
  final value = price / 100;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

const _moduleShadow = [
  BoxShadow(color: Color(0x0D1D4F91), blurRadius: 20, offset: Offset(0, 7)),
];

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: const Color(0xFFEEF1F5));
  }
}

class _FacilitiesCard extends StatelessWidget {
  const _FacilitiesCard({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    final facilities = house.displayFacilities.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: _moduleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.chair_outlined,
            title: '房屋设施',
            subtitle: '舒适生活所需配置',
          ),
          const SizedBox(height: 18),
          if (facilities.isEmpty)
            Text(
              '暂无设施信息',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: facilities.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisExtent: 72,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final facility = facilities[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _facilityIcon(facility),
                        color: AppColors.primary,
                        size: 21,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        facility.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _facilityIcon(HouseFacilityItem facility) {
    final configuredIcon = switch (facility.iconKey.trim().toLowerCase()) {
      'wifi' => Icons.wifi_rounded,
      'ac_unit' => Icons.ac_unit_rounded,
      'tv' => Icons.tv_outlined,
      'local_laundry_service' => Icons.local_laundry_service_outlined,
      'microwave' => Icons.microwave_outlined,
      'kitchen' => Icons.kitchen_outlined,
      'oven' => Icons.local_fire_department_outlined,
      'shower' => Icons.shower_outlined,
      'bathtub' => Icons.bathtub_outlined,
      'dry' => Icons.dry_cleaning_outlined,
      'bed' => Icons.bed_outlined,
      'chair' => Icons.chair_outlined,
      'checkroom' => Icons.checkroom_outlined,
      'living' => Icons.weekend_outlined,
      'desk' => Icons.desk_outlined,
      'curtains' => Icons.curtains_outlined,
      'security' => Icons.security_outlined,
      'lock' || 'smart_lock' => Icons.lock_outline_rounded,
      'nfc' => Icons.nfc_rounded,
      'fingerprint' => Icons.fingerprint_rounded,
      'bluetooth' => Icons.bluetooth_rounded,
      'pin' => Icons.pin_outlined,
      'smoke_free' => Icons.smoke_free_outlined,
      'fire_extinguisher' => Icons.fire_extinguisher_outlined,
      'elevator' => Icons.elevator_outlined,
      'local_parking' => Icons.local_parking_rounded,
      'fitness_center' => Icons.fitness_center_rounded,
      'pool' => Icons.pool_outlined,
      'yard' => Icons.yard_outlined,
      'balcony' => Icons.balcony_outlined,
      'garage' => Icons.garage_outlined,
      'store' => Icons.storefront_outlined,
      'local_shipping' => Icons.local_shipping_outlined,
      'pets' => Icons.pets_outlined,
      'sunny' => Icons.wb_sunny_outlined,
      'water' => Icons.water_drop_outlined,
      'eco' => Icons.eco_outlined,
      _ => null,
    };
    if (configuredIcon != null) return configuredIcon;

    final name = facility.name;
    if (name.contains('空调')) return Icons.ac_unit_rounded;
    if (name.contains('洗衣')) return Icons.local_laundry_service_outlined;
    if (name.contains('冰箱')) return Icons.kitchen_outlined;
    if (name.contains('网络') || name.contains('Wi')) {
      return Icons.wifi_rounded;
    }
    if (name.contains('热水') || name.contains('淋浴')) {
      return Icons.shower_outlined;
    }
    if (name.contains('床')) return Icons.bed_outlined;
    if (name.contains('电视')) return Icons.tv_outlined;
    return Icons.check_circle_outline_rounded;
  }
}

class _ImmersiveTourEntryCard extends ConsumerStatefulWidget {
  const _ImmersiveTourEntryCard({required this.house});

  final HouseDetail house;

  @override
  ConsumerState<_ImmersiveTourEntryCard> createState() =>
      _ImmersiveTourEntryCardState();
}

class _ImmersiveTourEntryCardState
    extends ConsumerState<_ImmersiveTourEntryCard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(immersiveTourAvailabilityProvider(widget.house.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      immersiveTourAvailabilityProvider(widget.house.id),
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
            : widget.house.coverImage;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: _openImmersiveTour,
            child: Container(
              height: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: _moduleShadow,
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
                          const Color(0xFF0B2748).withValues(alpha: 0.88),
                          const Color(0xFF0B2748).withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
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
                                    Icons.view_in_ar_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '沉浸式看房',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '720° 在线浏览房间场景与空间动线',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
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

  Future<void> _openImmersiveTour() async {
    final provider = immersiveTourAvailabilityProvider(widget.house.id);
    ref.invalidate(provider);
    final result = await ref.read(provider.future);
    if (!mounted ||
        result is! ApiSuccess<ImmersiveTourAvailability> ||
        !result.data.available) {
      return;
    }

    ref.invalidate(immersiveTourProvider(widget.house.id));
    await context.pushNamed(
      RouteNames.immersiveTour,
      pathParameters: {'houseId': widget.house.id},
    );
    if (mounted) {
      ref.invalidate(provider);
    }
  }
}

class _LandlordCard extends StatelessWidget {
  const _LandlordCard({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    final profile = house.landlordProfile;
    final avatar = profile?.avatarUrl.isNotEmpty == true
        ? profile!.avatarUrl
        : house.avatarUrl;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: profile == null ? null : () => _showProfile(context, profile),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: const Color(0xFFF0F2F5)),
            boxShadow: _moduleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                icon: Icons.person_outline_rounded,
                title: '房东信息',
                subtitle: '认证资料与服务评价',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Divider(height: 1, color: Color(0xFFEEF1F5)),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage:
                        !house.isPlatformSource && avatar.isNotEmpty
                        ? NetworkImage(avatar)
                        : null,
                    child: house.isPlatformSource || avatar.isEmpty
                        ? Icon(
                            house.isPlatformSource
                                ? Icons.apartment_rounded
                                : Icons.person,
                            color: AppColors.primary,
                            size: 26,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                house.isPlatformSource
                                    ? '勿忧管家'
                                    : profile?.name ?? house.landlordName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile?.isVerified ?? house.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 17,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          profile?.slogan.isNotEmpty == true
                              ? profile!.slogan
                              : house.responseDescription,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '评分 ${(profile?.rating ?? house.rating).toStringAsFixed(1)}  ·  已租 ${profile?.rentedCount ?? house.rentedCount} 套',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile?.phone?.isNotEmpty == true)
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: '拨打电话',
                        onPressed: () =>
                            launchUrl(Uri(scheme: 'tel', path: profile!.phone)),
                        icon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfile(BuildContext context, LandlordProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LandlordProfileSheet(
        profile: profile,
        isPlatform: house.isPlatformSource,
      ),
    );
  }
}

class _LandlordProfileSheet extends StatelessWidget {
  const _LandlordProfileSheet({
    required this.profile,
    required this.isPlatform,
  });

  final LandlordProfile profile;
  final bool isPlatform;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (profile.coverImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  profile.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: profile.avatarUrl.isNotEmpty
                    ? NetworkImage(profile.avatarUrl)
                    : null,
                child: profile.avatarUrl.isEmpty
                    ? Icon(
                        isPlatform ? Icons.apartment_rounded : Icons.person,
                        color: AppColors.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isPlatform ? '勿忧管家' : profile.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    if (profile.slogan.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        profile.slogan,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ProfileMetric(
                icon: Icons.star_rounded,
                label: '${profile.rating.toStringAsFixed(1)} 分',
              ),
              _ProfileMetric(
                icon: Icons.home_work_outlined,
                label: '已租 ${profile.rentedCount} 套',
              ),
              if (profile.serviceYears > 0)
                _ProfileMetric(
                  icon: Icons.workspace_premium_outlined,
                  label: '${profile.serviceYears} 年经验',
                ),
            ],
          ),
          if (profile.profileTags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: profile.profileTags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(),
            ),
          ],
          if (profile.introduction.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ProfileSection(title: '关于房东', content: profile.introduction),
          ],
          if (profile.serviceArea.isNotEmpty)
            _ProfileSection(title: '服务区域', content: profile.serviceArea),
          if (profile.responseDescription.isNotEmpty)
            _ProfileSection(
              title: '响应说明',
              content: profile.responseDescription,
            ),
          if (profile.contactTime.isNotEmpty)
            _ProfileSection(title: '方便联系', content: profile.contactTime),
          if (profile.hasPublicContact) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '公开联系方式',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (profile.phone?.isNotEmpty == true)
              _ContactTile(
                icon: Icons.phone_outlined,
                label: '电话',
                value: profile.phone!,
                onTap: () => launchUrl(Uri(scheme: 'tel', path: profile.phone)),
              ),
            if (profile.wechat?.isNotEmpty == true)
              _ContactTile(
                icon: Icons.chat_outlined,
                label: '微信',
                value: profile.wechat!,
                onTap: () => _copy(context, profile.wechat!, '微信号'),
              ),
            if (profile.email?.isNotEmpty == true)
              _ContactTile(
                icon: Icons.email_outlined,
                label: '邮箱',
                value: profile.email!,
                onTap: () =>
                    launchUrl(Uri(scheme: 'mailto', path: profile.email)),
              ),
          ],
        ],
      ),
    );
  }

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label已复制')));
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DetailSourceBadge extends StatelessWidget {
  const _DetailSourceBadge({required this.label, required this.isPlatform});

  final String label;
  final bool isPlatform;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isPlatform ? AppColors.primaryLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: isPlatform ? AppColors.primary : AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SmartLifeCard extends StatelessWidget {
  const _SmartLifeCard({required this.house});

  final HouseDetail house;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: _moduleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.auto_awesome_outlined,
            title: '智能生活',
            subtitle: '让入住更便捷、更安心',
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: house.isSmartLockSupported
                  ? AppColors.primaryLight
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 24,
                  color: house.isSmartLockSupported
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '智能门锁',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        house.isSmartLockSupported
                            ? '支持无钥匙便捷入住'
                            : '该房源暂未配置智能门锁',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  house.isSmartLockSupported
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline,
                  color: house.isSmartLockSupported
                      ? AppColors.primary
                      : AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: _moduleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.notes_rounded,
            title: '房源描述',
            subtitle: '更多房屋与周边信息',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            house.description.isEmpty ? '房东暂未填写更多房源描述。' : house.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.75,
              fontSize: 14,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        10,
        AppSpacing.pageHorizontal,
        10 + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
        boxShadow: [
          BoxShadow(
            color: Color(0x120B2748),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                side: const BorderSide(color: Color(0xFFBBD9FF)),
                foregroundColor: AppColors.primary,
                fixedSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _openViewing(context),
              child: const Text('预约看房'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textMuted,
                elevation: 0,
                fixedSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _openApplication(context, ref),
              child: Text(_applicationLabel),
            ),
          ),
        ],
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

  Future<void> _openApplication(BuildContext context, WidgetRef ref) async {
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

    final authStatus = await _getRealNameStatus(context, ref);
    if (!context.mounted) return;
    if (authStatus == null) return;
    if (authStatus.authStatus != RealNameAuthStatus.verified) {
      final verified = await context.pushNamed<bool>(
        RouteNames.realNameAuth,
        queryParameters: {'houseId': house.id},
      );
      if (!context.mounted || verified != true) return;
    }
    if (!context.mounted) return;
    _showRentSheet(context);
  }

  Future<RealNameAuthStatusResponse?> _getRealNameStatus(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      return await ref.read(realNameAuthApiProvider).getStatus();
    } catch (_) {
      if (context.mounted) {
        AppToast.show(context, '认证状态获取失败，请稍后重试', type: AppToastType.error);
      }
      return null;
    }
  }

  void _showRentSheet(BuildContext context) {
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
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(color: AppColors.border),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -38),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                    AppSpacing.pageHorizontal,
                    0,
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
                AppSpacing.pageHorizontal,
                AppSpacing.md,
                AppSpacing.pageHorizontal,
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
