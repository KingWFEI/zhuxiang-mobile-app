import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/datasources/mock_house_datasource.dart';
import '../../domain/entities/house.dart';
import '../widgets/house_image_placeholder.dart';

class HouseDetailPage extends StatelessWidget {
  const HouseDetailPage({required this.houseId, super.key});

  final String houseId;

  @override
  Widget build(BuildContext context) {
    final house = MockHouseDatasource.findById(houseId);
    if (house == null) {
      return const Scaffold(body: Center(child: Text('房源不存在')));
    }

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
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: CircleAvatar(
          backgroundColor: AppColors.surface,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new),
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
              icon: const Icon(Icons.ios_share),
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
      flexibleSpace: const FlexibleSpaceBar(
        background: HouseImagePlaceholder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        110,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      house.title,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text.rich(
                      TextSpan(
                        text: '¥ ${house.price}',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontSize: 34,
                        ),
                        children: [
                          TextSpan(text: ' /月', style: AppTextStyles.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: const Icon(
                  Icons.verified_user,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: const Text('平台验真'),
                backgroundColor: AppColors.primaryLight,
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.iconMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${house.location} · ${house.community}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.iconMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: house.tags.map((tag) => _DetailTag(tag)).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.md),
          _FacilitiesCard(house: house),
          const SizedBox(height: AppSpacing.md),
          const _LandlordCard(),
          const SizedBox(height: AppSpacing.md),
          _SmartLifeCard(house: house),
          const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
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
          Icon(icon, color: AppColors.textSecondary, size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyMedium),
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
              Text('房屋设施', style: AppTextStyles.titleMedium),
              const Spacer(),
              Text('查看全部', style: AppTextStyles.bodyLarge),
              const Icon(Icons.chevron_right, color: AppColors.iconMuted),
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
                        size: 30,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        house.facilities[index],
                        style: AppTextStyles.bodyMedium,
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
  const _LandlordCard();

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
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, color: AppColors.primary, size: 36),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('张先生 · 房东', style: AppTextStyles.titleMedium),
                    const SizedBox(width: AppSpacing.sm),
                    const Chip(
                      label: Text('已实名'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    ),
                  ],
                ),
                Text(
                  '回复及时 · 评分 4.9 · 已租 23 套',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showTodo(context),
            icon: const Icon(Icons.chat_bubble, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () => _showTodo(context),
            icon: const Icon(Icons.phone, color: AppColors.primary),
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
          const Icon(Icons.lock, size: 70, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('智能生活', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  house.isSmartLockSupported ? '智能门锁已连接，门锁运行正常' : '该房源暂不支持智能门锁',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.iconMuted),
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
