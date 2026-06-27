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
import '../../data/models/profile_models.dart';
import '../../data/providers/profile_providers.dart';
import '../widgets/profile_menu_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                isVerified: user.isVerified,
              ),
            const SizedBox(height: AppSpacing.lg),
            if (user != null) const _CurrentHomeCard(),
            const SizedBox(height: AppSpacing.lg),
            const _MenuGrid(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '更多服务',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: const [
                Expanded(
                  child: ProfileMenuTile(
                    icon: Icons.group,
                    label: '邀请合租',
                    subtitle: '与好友一起安心租房',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ProfileMenuTile(
                    icon: Icons.support_agent,
                    label: '联系客服',
                    subtitle: '7×24小时为您服务',
                    color: Color(0xFF7667F8),
                  ),
                ),
              ],
            ),
          ],
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
                  Icon(Icons.home_work, color: AppColors.primary, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('住享', style: AppTextStyles.logoTitle),
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
    required this.isVerified,
  });

  final String nickname;
  final String phone;
  final bool isVerified;

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
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, color: AppColors.primary, size: 30),
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

class _CurrentHomeCard extends ConsumerWidget {
  const _CurrentHomeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(currentHomeProvider);

    return result.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final home = data.home;
        final lock = data.lock;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F2FE), Colors.white],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -8,
                right: 96,
                child: Image.asset(
                  'assets/lock_style.png',
                  width: 76,
                  fit: BoxFit.fitWidth,
                ),
              ),
              Row(
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
                        _LockStatusChip(lock: lock),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 94,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        textStyle: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('查看门锁'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _LockStatusChip extends StatelessWidget {
  const _LockStatusChip({required this.lock});

  final LockInfo? lock;

  @override
  Widget build(BuildContext context) {
    final hasLock = lock != null;
    final label = lock?.statusLabel ?? '未绑定门锁';
    final iconColor = hasLock && lock!.isOnline && !lock!.isLowBattery
        ? AppColors.secondary
        : AppColors.warning;
    final bgColor = hasLock && lock!.isOnline && !lock!.isLowBattery
        ? const Color(0xFFE3FAF4)
        : const Color(0xFFFFF4E5);
    final textColor = hasLock && lock!.isOnline && !lock!.isLowBattery
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

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.description, '我的租约', AppColors.primary),
      (Icons.lock_clock, '开门记录', AppColors.secondary),
      (Icons.account_balance_wallet, '押金账单', AppColors.warning),
      (Icons.build, '报修服务', AppColors.warning),
      (Icons.badge, '实名认证', AppColors.primary),
      (Icons.star, '我的收藏', const Color(0xFF7667F8)),
      (Icons.settings, '设置', AppColors.iconMuted),
      (Icons.help, '帮助中心', AppColors.primary),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.18,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          VoidCallback? onTap;

          if (index == 0) {
            onTap = () => context.pushNamed(RouteNames.lease);
          } else if (index == 1) {
            onTap = () => context.pushNamed(RouteNames.unlockRecords);
          } else if (index == 3) {
            onTap = () => context.pushNamed(RouteNames.repairs);
          } else if (index == 6) {
            onTap = () => context.pushNamed(RouteNames.settings);
          }

          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
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
    );
  }
}
