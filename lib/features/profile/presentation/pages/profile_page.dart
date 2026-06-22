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
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
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
            const _CurrentHomeCard(),
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
            const SizedBox(height: AppSpacing.lg),
            if (user != null)
              OutlinedButton(
                onPressed: () => _confirmLogout(context, ref),
                child: const Text('退出登录'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.goNamed(RouteNames.login);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
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
              const Spacer(),
              Text(
                '我的',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
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
          const Icon(Icons.chevron_right, color: AppColors.iconMuted, size: 20),
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
                Text('登录后查看租约、账单和门锁', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          SizedBox(
            width: 76,
            child: ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: EdgeInsets.zero,
                textStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('去登录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentHomeCard extends StatelessWidget {
  const _CurrentHomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFE0F2FE), // 浅蓝色
            Colors.white, // 白色
          ],
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
              "assets/lock_style.png",
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
                      '3栋2单元1201',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // 这里的值可以随意调整
                      ),
                      avatar: const Icon(
                        Icons.lock,
                        color: AppColors.secondary,
                        size: 14,
                      ),
                      label: Text(
                        '门锁已上锁',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: const Color(0xFFE3FAF4),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 94,
                child: OutlinedButton.icon(
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
                  icon: const Icon(Icons.chevron_right, size: 16),
                  label: const Text('查看门锁'),
                ),
              ),
            ],
          ),
        ],
      ),
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
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: index == 0
                // TODO: 联调完成后恢复登录校验，未登录用户应跳转登录页。
                ? () => context.pushNamed(RouteNames.lease)
                : null,
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
