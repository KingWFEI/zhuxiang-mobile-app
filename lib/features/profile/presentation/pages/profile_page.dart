import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/router/app_mode_controller.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_card_spacing.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../message/data/providers/message_providers.dart';
import '../../data/models/profile_models.dart';
import '../../data/providers/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final homeState = ref.watch(currentHomeProvider);
    final overview = user == null
        ? null
        : ref.watch(profileOverviewProvider).valueOrNull;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackground()),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref, user != null),
              child: ListView(
                key: const Key('profile-page-scroll'),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  0,
                  AppSpacing.pageHorizontal,
                  116,
                ),
                children: [
                  const _ProfileTopBar(),
                  const SizedBox(height: 2),
                  if (user == null)
                    _GuestCard(onLogin: () => context.goNamed(RouteNames.login))
                  else
                    _UserIdentityCard(
                      user: user,
                      favoriteCount: overview?.favoriteCount ?? 0,
                      appointmentCount: overview?.appointmentCount ?? 0,
                      isVerified: overview?.isVerified ?? user.isVerified,
                      onTap: () => context.pushNamed(RouteNames.settings),
                    ),
                  if (user != null) ...[
                    const SizedBox(height: AppCardSpacing.betweenCards),
                    _ProfileDashboard(homeState: homeState),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref, bool signedIn) async {
    try {
      await Future.wait([
        ref.refresh(currentHomeProvider.future),
        if (signedIn) ref.refresh(profileOverviewProvider.future),
      ]);
    } on Object {
      // 页面会继续显示原有功能入口，接口错误不阻塞下拉刷新结束。
    }
    if (signedIn) {
      await ref.read(messageControllerProvider.notifier).refreshUnreadCounts();
    }
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF4FF), Color(0xFFF7FAFF), Color(0xFFF4F7FC)],
          stops: [0, 0.32, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF84B9FF).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -110,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: -24,
            child: Opacity(
              opacity: 0.12,
              child: Image.asset('assets/home_bk.png', width: 310),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

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
              'assets/home_bk.png',
              width: 300,
              fit: BoxFit.fitWidth,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserIdentityCard extends StatelessWidget {
  const _UserIdentityCard({
    required this.user,
    required this.favoriteCount,
    required this.appointmentCount,
    required this.isVerified,
    required this.onTap,
  });

  final AuthUser user;
  final int favoriteCount;
  final int appointmentCount;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user.avatarUrl.trim().isNotEmpty;
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(26),
      elevation: 0,
      child: InkWell(
        key: const Key('profile-identity-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142A67B7),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFEAF3FF),
                    backgroundImage: hasAvatar
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: hasAvatar
                        ? null
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.nickname.isEmpty ? '勿忧用户' : user.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RoleBadge(label: _roleLabel(user.role)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.maskedPhone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF9AA6B7),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 17),
                child: Divider(height: 1, color: Color(0xFFE9EEF6)),
              ),
              Row(
                children: [
                  Expanded(
                    child: _IdentityMetric(
                      icon: HugeIcons.strokeRoundedStar,
                      label: '收藏',
                      value: '$favoriteCount',
                      onTap: () => context.pushNamed(RouteNames.favoriteHouses),
                    ),
                  ),
                  const _MetricDivider(),
                  Expanded(
                    child: _IdentityMetric(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      label: '预约',
                      value: '$appointmentCount',
                      onTap: () => context.pushNamed(RouteNames.appointment),
                    ),
                  ),
                  const _MetricDivider(),
                  Expanded(
                    child: _IdentityMetric(
                      icon: HugeIcons.strokeRoundedUserIdVerification,
                      label: '实名认证',
                      value: isVerified ? '已认证' : '未认证',
                      valueColor: isVerified
                          ? AppColors.primary
                          : AppColors.warning,
                      valueFontSize: isVerified ? null : 13,
                      onTap: () => context.pushNamed(RouteNames.realNameAuth),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFBFD7FF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2875E8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IdentityMetric extends StatelessWidget {
  const _IdentityMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
    this.valueFontSize,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;
  final double? valueFontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, color: const Color(0xFF347FF0), size: 22),
              const SizedBox(width: 7),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: valueColor ?? AppColors.textPrimary,
                        fontSize: valueFontSize ?? 15,
                        fontWeight: FontWeight.w800,
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
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: const Color(0xFFE7EDF6));
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142A67B7),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFEAF3FF),
            child: Icon(
              Icons.person_outline_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '登录勿忧管家',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  '查看租约、账单和门锁服务',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }
}

class _ProfileDashboard extends ConsumerStatefulWidget {
  const _ProfileDashboard({required this.homeState});

  final AsyncValue<({List<CurrentHome> homes, LockInfo? lock})?> homeState;

  @override
  ConsumerState<_ProfileDashboard> createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends ConsumerState<_ProfileDashboard> {
  final PageController _homeController = PageController();
  int _homePage = 0;

  static const _commonServices = [
    _ServiceSpec(HugeIcons.strokeRoundedFile01, '我的租约', _ServiceAction.lease),
    _ServiceSpec(HugeIcons.strokeRoundedWallet01, '我的账单', _ServiceAction.bill),
    _ServiceSpec(
      HugeIcons.strokeRoundedReceiptText,
      '支付记录',
      _ServiceAction.payments,
    ),
    _ServiceSpec(HugeIcons.strokeRoundedRepair, '报修服务', _ServiceAction.repair),
    _ServiceSpec(
      HugeIcons.strokeRoundedCalendar01,
      '我的预约',
      _ServiceAction.appointment,
    ),
    _ServiceSpec(HugeIcons.strokeRoundedLock, '门锁管理', _ServiceAction.lock),
    _ServiceSpec(
      HugeIcons.strokeRoundedShoppingBag01,
      '我的订单',
      _ServiceAction.orders,
    ),
    _ServiceSpec(HugeIcons.strokeRoundedStar, '我的收藏', _ServiceAction.favorite),
  ];

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.homeState.valueOrNull;
    final homes = data?.homes ?? const <CurrentHome>[];
    final lock = data?.lock;
    final isLandlord = ref.watch(
      authControllerProvider.select(
        (state) => state.user?.role.usesLandlordShell ?? false,
      ),
    );
    final moreServices = [
      const _ServiceSpec(
        HugeIcons.strokeRoundedUserIdVerification,
        '实名认证',
        _ServiceAction.realName,
      ),
      _ServiceSpec(
        isLandlord
            ? HugeIcons.strokeRoundedDashboardSquare01
            : HugeIcons.strokeRoundedRealEstate01,
        isLandlord ? '房东工作台' : '房东认证',
        _ServiceAction.landlord,
      ),
      const _ServiceSpec(
        HugeIcons.strokeRoundedCustomerService01,
        '联系管家',
        _ServiceAction.customerService,
      ),
      const _ServiceSpec(
        HugeIcons.strokeRoundedSettings01,
        '设置',
        _ServiceAction.settings,
      ),
    ];

    return Column(
      children: [
        if (homes.isNotEmpty) ...[
          _SectionCard(
            title: '正在租住',
            actionLabel: '查看租约',
            onAction: () => context.pushNamed(RouteNames.lease),
            child: Column(
              children: [
                SizedBox(
                  height: 172,
                  child: PageView.builder(
                    key: const Key('profile-current-home-carousel'),
                    controller: _homeController,
                    itemCount: homes.length,
                    onPageChanged: (value) {
                      setState(() => _homePage = value);
                    },
                    itemBuilder: (context, index) {
                      final home = homes[index];
                      return _CurrentHomeCard(
                        home: home,
                        onTap: () => context.pushNamed(
                          RouteNames.rentedHomeDetail,
                          pathParameters: {'leaseId': home.leaseId},
                        ),
                        onUnlock: home.hasSmartLock
                            ? () => context.pushNamed(
                                RouteNames.tenantLockUnlock,
                                pathParameters: {'leaseId': home.leaseId},
                              )
                            : null,
                      );
                    },
                  ),
                ),
                if (homes.length > 1) ...[
                  const SizedBox(height: 10),
                  _PageDots(count: homes.length, current: _homePage),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppCardSpacing.betweenCards),
        ],
        _ServiceSection(
          title: '常用服务',
          services: _commonServices,
          onTap: (service) =>
              _openService(context, service.action, homes: homes, lock: lock),
        ),
        const SizedBox(height: AppCardSpacing.betweenCards),
        _ServiceSection(
          title: '更多功能',
          services: moreServices,
          onTap: (service) =>
              _openService(context, service.action, homes: homes, lock: lock),
        ),
      ],
    );
  }

  Future<void> _openService(
    BuildContext context,
    _ServiceAction action, {
    required List<CurrentHome> homes,
    required LockInfo? lock,
  }) async {
    switch (action) {
      case _ServiceAction.lease:
        context.pushNamed(RouteNames.lease);
      case _ServiceAction.bill:
        context.pushNamed(RouteNames.bill);
      case _ServiceAction.payments:
        context.pushNamed(RouteNames.paymentRecords);
      case _ServiceAction.repair:
        context.pushNamed(RouteNames.repairs);
      case _ServiceAction.appointment:
        context.pushNamed(RouteNames.appointment);
      case _ServiceAction.lock:
        final leaseId = lock?.isLeaseInvalidForLock == false
            ? lock?.leaseId ?? ''
            : homes
                      .where(
                        (home) =>
                            home.leaseId.isNotEmpty &&
                            home.lockId?.isNotEmpty == true &&
                            home.lockStatus.toUpperCase() != 'UNBOUND',
                      )
                      .map((home) => home.leaseId)
                      .firstOrNull ??
                  '';
        if (leaseId.isNotEmpty) {
          context.pushNamed(
            RouteNames.tenantLockUnlock,
            pathParameters: {'leaseId': leaseId},
          );
        } else {
          context.pushNamed(RouteNames.lock);
        }
      case _ServiceAction.orders:
        context.pushNamed(RouteNames.rentOrders);
      case _ServiceAction.favorite:
        context.pushNamed(RouteNames.favoriteHouses);
      case _ServiceAction.realName:
        context.pushNamed(RouteNames.realNameAuth);
      case _ServiceAction.landlord:
        final isLandlord =
            ref.read(authControllerProvider).user?.role.usesLandlordShell ??
            false;
        if (!isLandlord) {
          context.pushNamed(RouteNames.landlordVerify);
          return;
        }
        await _showRoleSwitchTransition(context);
        if (!context.mounted) return;
        await ref.read(appModeProvider.notifier).setMode(AppMode.landlord);
        if (context.mounted) {
          context.goNamed(RouteNames.landlordWorkbench);
        }
      case _ServiceAction.customerService:
        context.pushNamed(RouteNames.customerServiceEnter);
      case _ServiceAction.settings:
        context.pushNamed(RouteNames.settings);
    }
  }
}

Future<void> _showRoleSwitchTransition(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (dialogContext, _, _) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
      });
      return const _RoleSwitchOverlay();
    },
    transitionBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

class _RoleSwitchOverlay extends StatelessWidget {
  const _RoleSwitchOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F8FF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '\u6b63\u5728\u8fdb\u5165\u623f\u4e1c\u5de5\u4f5c\u53f0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 17, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2D67AD),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (actionLabel != null)
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            actionLabel!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: Color(0xFF9AA6B7),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _CurrentHomeCard extends StatelessWidget {
  const _CurrentHomeCard({
    required this.home,
    required this.onTap,
    this.onUnlock,
  });

  final CurrentHome home;
  final VoidCallback onTap;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final roomLabel = [
      home.community,
      home.addressLabel,
    ].where((value) => value.isNotEmpty).join(' · ');
    final title = roomLabel.isNotEmpty
        ? roomLabel
        : home.displayTitle.isNotEmpty
        ? home.displayTitle
        : '当前租住房源';
    final address = home.address.isNotEmpty ? home.address : '地址信息待完善';
    final invalid = const {
      'TERMINATED',
      'EXPIRED',
      'CHECKED_OUT',
      'CANCELLED',
    }.contains(home.leaseStatus.toUpperCase());
    final hasImage = home.coverImage.trim().isNotEmpty;
    final hasLock = home.hasSmartLock;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFEDF1F7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F204C86),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 104,
                  height: 124,
                  child: hasImage
                      ? Image.network(
                          home.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _HomeImageFallback(),
                        )
                      : const _HomeImageFallback(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _StatusPill(
                          label: invalid ? '租约已失效' : '租约有效',
                          foreground: invalid
                              ? AppColors.textMuted
                              : const Color(0xFF07966E),
                          background: invalid
                              ? const Color(0xFFF1F3F5)
                              : const Color(0xFFE3F9F1),
                        ),
                        if (hasLock)
                          const _StatusPill(
                            label: '门锁可用',
                            foreground: Color(0xFF2875E8),
                            background: Color(0xFFEAF3FF),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          '查看房间详情',
                          style: TextStyle(
                            color: Color(0xFF347FF0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (hasLock)
                          SizedBox(
                            height: 30,
                            child: FilledButton.icon(
                              key: Key('current-home-unlock-${home.leaseId}'),
                              onPressed: onUnlock,
                              icon: const Icon(
                                Icons.lock_open_rounded,
                                size: 14,
                              ),
                              label: const Text('开锁'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF9AA6B7),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeImageFallback extends StatelessWidget {
  const _HomeImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F1FF), Color(0xFFF4F8FF)],
        ),
      ),
      child: const Icon(
        Icons.apartment_rounded,
        size: 40,
        color: Color(0xFF75A7EE),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFCADAF2),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  const _ServiceSection({
    required this.title,
    required this.services,
    required this.onTap,
  });

  final String title;
  final List<_ServiceSpec> services;
  final ValueChanged<_ServiceSpec> onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14204C86),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.86,
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final service = services[index];
            return _ServiceTile(service: service, onTap: () => onTap(service));
          },
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final _ServiceSpec service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('profile-service-${service.action.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: service.icon,
                size: 29,
                color: const Color(0xFF202C3D),
              ),
              const SizedBox(height: 9),
              Text(
                service.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSpec {
  const _ServiceSpec(this.icon, this.label, this.action);

  final List<List<dynamic>> icon;
  final String label;
  final _ServiceAction action;
}

enum _ServiceAction {
  lease,
  bill,
  payments,
  repair,
  appointment,
  lock,
  orders,
  favorite,
  realName,
  landlord,
  customerService,
  settings,
}

String _roleLabel(UserRole role) {
  return switch (role) {
    UserRole.tenant => '租客',
    UserRole.landlord => '房东',
    UserRole.housekeeper => '管家',
    UserRole.admin => '管理员',
  };
}
