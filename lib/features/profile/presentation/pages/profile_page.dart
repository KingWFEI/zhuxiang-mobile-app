import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../data/models/profile_models.dart';
import '../../data/providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    Future<void> handleRefresh() async {
      ref.invalidate(currentHomeProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: handleRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              96,
            ),
            children: [
              const _ProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              if (user == null)
                _GuestCard(onLogin: () => context.goNamed(RouteNames.login))
              else
                _UserCard(
                  nickname: user.nickname,
                  phone: user.maskedPhone,
                  avatarUrl: user.avatarUrl,
                  isVerified: user.isVerified,
                  onTap: () => context.pushNamed(RouteNames.settings),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (user != null) const _DashboardCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -18,
            right: -40,
            child: Image.asset(
              "assets/home_bk.png",
              width: 300,
              fit: BoxFit.fitWidth,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppLogo(),
                  Spacer(),
                  Icon(Icons.notifications_none, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('安心居住，住享相伴', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.nickname,
    required this.phone,
    required this.avatarUrl,
    required this.isVerified,
    required this.onTap,
  });

  final String nickname;
  final String phone;
  final String avatarUrl;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: hasAvatar
                  ? null
                  : const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 30,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(phone, style: AppTextStyles.bodySmall),
                  if (isVerified) const SizedBox(height: AppSpacing.xs),
                  if (isVerified)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: const Icon(
                        Icons.verified_user,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        '安心住户',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onLogin});

  final VoidCallback onLogin;

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
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '未登录',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '登录后查看租约、账单和门锁',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends ConsumerWidget {
  const _DashboardCard();

  static const _menuItems = [
    (Icons.description, '我的租约', AppColors.primary),
    (Icons.receipt_long, '我的订单', AppColors.primary),
    (Icons.payments, '支付记录', AppColors.secondary),
    (Icons.lock_clock, '开门记录', AppColors.secondary),
    (Icons.account_balance_wallet, '押金账单', AppColors.warning),
    (Icons.build, '报修服务', AppColors.warning),
    (Icons.badge, '实名认证', AppColors.primary),
    (Icons.star, '我的收藏', Color(0xFF7667F8)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(currentHomeProvider);

    return result.when(
      data: (data) => _buildContent(context, data),
      error: (error, stackTrace) => _buildMenuOnly(context),
      loading: () => _buildMenuOnly(context),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ({CurrentHome? home, LockInfo? lock})? data,
  ) {
    final home = data?.home;
    final lock = data?.lock;

    final lockInvalid =
        lock?.isLeaseInvalidForLock == true ||
        (home?.leaseStatus.isNotEmpty == true &&
            const [
              'TERMINATED',
              'EXPIRED',
              'CHECKED_OUT',
              'CANCELLED',
            ].contains(home!.leaseStatus.toUpperCase()));

    final leaseId = lockInvalid
        ? ''
        : home?.leaseId.isNotEmpty == true
        ? home!.leaseId
        : lock?.leaseId ?? '';

    final hasHomeData =
        data != null && (home?.addressLabel.isNotEmpty == true || lock != null);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F2FE), Color.fromARGB(255, 255, 255, 255)],
          stops: [0.0, 0.5],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 门锁区域 ──
          if (hasHomeData)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  right: 96,
                  child: Image.asset(
                    'assets/lock_style.png',
                    width: 80,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('当前居住', style: AppTextStyles.bodySmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              home?.addressLabel ?? '--',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _LockStatusChip(
                              lock: lock,
                              leaseInvalid: lockInvalid,
                            ),
                            // if (home?.address.isNotEmpty == true) ...[
                            //   const SizedBox(height: AppSpacing.lg),
                            //   Text(
                            //     home!.address,
                            //     style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                            //   ),
                            // ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 84,
                        child: OutlinedButton(
                          onPressed: leaseId.isEmpty
                              ? null
                              : () => context.pushNamed(
                                  RouteNames.tenantLockUnlock,
                                  pathParameters: {'leaseId': leaseId},
                                ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            textStyle: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          child: const Text('查看门锁'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          // ── 菜单网格 ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.18,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
              ),
              itemBuilder: (ctx, index) {
                final item = _menuItems[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => _onMenuItemTap(context, index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, color: item.$3, size: 24),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.$2,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOnly(BuildContext context) {
    return _buildContent(context, null);
  }

  void _onMenuItemTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.pushNamed(RouteNames.lease);
      case 1:
        context.pushNamed(RouteNames.rentOrders);
      case 2:
        context.pushNamed(RouteNames.paymentRecords);
      case 3:
        context.pushNamed(RouteNames.unlockRecords);
      case 5:
        context.pushNamed(RouteNames.repairs);
      case 6:
        context.pushNamed(RouteNames.realNameAuth);
      case 7:
        context.pushNamed(RouteNames.favoriteHouses);
    }
  }
}

class _LockStatusChip extends StatelessWidget {
  const _LockStatusChip({required this.lock, this.leaseInvalid = false});

  final LockInfo? lock;
  final bool leaseInvalid;

  @override
  Widget build(BuildContext context) {
    final hasLock = lock != null && !leaseInvalid;
    final label = leaseInvalid ? '租约已失效' : lock?.statusLabel ?? '未绑定门锁';
    final iconColor = leaseInvalid
        ? AppColors.textMuted
        : hasLock && lock!.isOnline && !lock!.isLowBattery
        ? AppColors.secondary
        : AppColors.warning;
    final bgColor = leaseInvalid
        ? const Color(0xFFF5F5F5)
        : hasLock && lock!.isOnline && !lock!.isLowBattery
        ? const Color(0xFFE3FAF4)
        : const Color(0xFFFFF4E5);
    final textColor = leaseInvalid
        ? AppColors.textMuted
        : hasLock && lock!.isOnline && !lock!.isLowBattery
        ? AppColors.secondary
        : AppColors.warning;

    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      avatar: Icon(
        hasLock ? Icons.lock : Icons.lock_open,
        color: iconColor,
        size: 14,
      ),
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
      side: BorderSide.none,
    );
  }
}
