import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../home/presentation/widgets/home_search_bar.dart';
import '../../data/datasources/mock_house_datasource.dart';
import '../../domain/entities/house.dart';
import '../widgets/house_card.dart';

class FindHomePage extends StatelessWidget {
  const FindHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final houses = MockHouseDatasource.houses;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            120,
          ),
          itemCount: houses.length + 4,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) return const _FindHeader();
            if (index == 1) {
              return const HomeSearchBar(hintText: '搜索小区、地铁、区域或房源');
            }
            if (index == 2) return const _FilterRow();
            if (index == 3) return const _RecommendBanner();

            final house = houses[index - 4];
            return HouseCard(
              house: house,
              onTap: () => _openDetail(context, house),
            );
          },
        ),
      ),
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
        Spacer(),
        Icon(Icons.notifications_none, size: 30),
        SizedBox(width: AppSpacing.lg),
        Icon(Icons.qr_code_scanner, size: 28),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['区域', '租金', '户型', '更多'];
    return Row(
      children: [
        for (final label in labels) ...[
          Expanded(child: _FilterChip(label: label)),
          if (label != labels.last) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}

class _RecommendBanner extends StatelessWidget {
  const _RecommendBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(
            '为你推荐安心好房',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 17),
          ),
          const Spacer(),
          const Icon(Icons.apartment, color: AppColors.primarySoft, size: 54),
        ],
      ),
    );
  }
}
