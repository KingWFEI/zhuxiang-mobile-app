import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../house/data/datasources/mock_house_datasource.dart';
import '../../../house/domain/entities/house.dart';
import '../../../house/presentation/widgets/house_card.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_service_entry.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final houses = MockHouseDatasource.getRecommendedHouses();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            120,
          ),
          children: [
            _HomeHeader(name: user?.nickname ?? 'King'),
            const SizedBox(height: AppSpacing.xl),
            HomeSearchBar(
              hintText: '搜索小区、地址或房源',
              onTap: () => context.goNamed(RouteNames.search),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SmartLockCard(),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: '房源推荐',
              actionText: '查看更多',
              onActionPressed: () => context.goNamed(RouteNames.search),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: houses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final house = houses[index];
                return HouseCard(
                  house: house,
                  compact: true,
                  onTap: () => _openDetail(context, house),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: '便捷服务'),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.9,
              children: const [
                HomeServiceEntry(
                  icon: Icons.description,
                  label: '我的租约',
                  color: AppColors.primary,
                ),
                HomeServiceEntry(
                  icon: Icons.lock_clock,
                  label: '开门记录',
                  color: AppColors.secondary,
                ),
                HomeServiceEntry(
                  icon: Icons.build,
                  label: '报修服务',
                  color: AppColors.warning,
                ),
                HomeServiceEntry(
                  icon: Icons.support_agent,
                  label: '在线客服',
                  color: Color(0xFF7667F8),
                ),
              ],
            ),
          ],
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          const Positioned.fill(child: _HeaderBuilding()),
          Column(
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
                  Spacer(),
                  Icon(Icons.notifications_none, size: 30),
                  SizedBox(width: AppSpacing.lg),
                  Icon(Icons.qr_code_scanner, size: 28),
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
        ],
      ),
    );
  }
}

class _HeaderBuilding extends StatelessWidget {
  const _HeaderBuilding();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            colors: [Color(0x00FFFFFF), AppColors.primaryLight],
          ),
        ),
        child: const Icon(
          Icons.apartment,
          size: 96,
          color: AppColors.primarySoft,
        ),
      ),
    );
  }
}

class _SmartLockCard extends StatelessWidget {
  const _SmartLockCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('我的家', style: AppTextStyles.titleLarge),
              const Icon(Icons.arrow_drop_down),
              const Spacer(),
              const Icon(Icons.lock, color: AppColors.textPrimary, size: 72),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('3栋2单元1201', style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.bluetooth, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '蓝牙已连接',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('信号强', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTodo(context),
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('蓝牙开锁'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTodo(context),
                  icon: const Icon(Icons.wifi),
                  label: const Text('远程开锁'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTodo(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('开锁能力暂未接入')));
  }
}
