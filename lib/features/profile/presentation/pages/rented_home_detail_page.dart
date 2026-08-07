import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_api_error_view.dart';
import '../../data/models/profile_models.dart';
import '../../data/providers/profile_providers.dart';

class RentedHomeDetailPage extends ConsumerWidget {
  const RentedHomeDetailPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(currentHomeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppApiErrorView(
          error: error,
          title: '房间信息加载失败',
          actionLabel: '重新加载',
          onRetry: () => ref.invalidate(currentHomeProvider),
        ),
        data: (data) {
          final home = _findHome(data?.homes ?? const []);
          if (home == null) {
            return _UnavailableView(
              title: '当前租约已结束或无法访问',
              actionLabel: '返回我的',
              onAction: () => context.goNamed(RouteNames.profile),
            );
          }
          return _RentedHomeContent(
            home: home,
            onRefresh: () => ref.refresh(currentHomeProvider.future),
          );
        },
      ),
    );
  }

  CurrentHome? _findHome(List<CurrentHome> homes) {
    for (final home in homes) {
      if (home.leaseId == leaseId) return home;
    }
    return null;
  }
}

class _RentedHomeContent extends StatelessWidget {
  const _RentedHomeContent({required this.home, required this.onRefresh});

  final CurrentHome home;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 294,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _RoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed(RouteNames.profile);
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeroImage(home: home),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                child: Column(
                  children: [
                    _OverviewCard(home: home),
                    const SizedBox(height: 14),
                    _LeaseCard(home: home),
                    const SizedBox(height: 14),
                    _HouseInfoCard(home: home),
                    const SizedBox(height: 14),
                    _AccessCard(home: home),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.home});

  final CurrentHome home;

  @override
  Widget build(BuildContext context) {
    final hasImage = home.coverImage.trim().isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.network(
            home.coverImage,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ImageFallback(),
          )
        else
          const _ImageFallback(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33000000),
                Colors.transparent,
                Color(0x55000000),
              ],
              stops: [0, 0.58, 1],
            ),
          ),
        ),
        const Positioned(left: 20, bottom: 40, child: _LivingBadge()),
      ],
    );
  }
}

class _LivingBadge extends StatelessWidget {
  const _LivingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0BA879),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x33004733), blurRadius: 12)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_rounded, size: 14, color: Colors.white),
          SizedBox(width: 5),
          Text(
            '正在租住',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.home});

  final CurrentHome home;

  @override
  Widget build(BuildContext context) {
    final title = home.displayTitle.isEmpty ? '我的房间' : home.displayTitle;
    final rent = home.monthlyRent;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SourceBadge(sourceType: home.sourceType),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  home.address.isEmpty ? '地址信息待完善' : home.address,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (rent != null) ...[
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '¥', style: TextStyle(fontSize: 16)),
                  TextSpan(
                    text: _yuan(rent),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const TextSpan(
                    text: '/月',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                color: Color(0xFF2F7DEA),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaseCard extends StatelessWidget {
  const _LeaseCard({required this.home});

  final CurrentHome home;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      icon: Icons.description_outlined,
      title: '租约信息',
      action: TextButton(
        onPressed: () => context.pushNamed(
          RouteNames.leaseDetail,
          pathParameters: {'leaseId': home.leaseId},
        ),
        child: const Text('查看租约'),
      ),
      children: [
        _InfoRow(
          label: '租赁周期',
          value: '${_date(home.leaseStartDate)} 至 ${_date(home.leaseEndDate)}',
        ),
        _InfoRow(
          label: '付款方式',
          value: home.paymentMethod.isEmpty ? '--' : home.paymentMethod,
        ),
        _InfoRow(
          label: '押金',
          value: home.deposit == null ? '--' : '¥${_yuan(home.deposit!)}',
          showDivider: false,
        ),
      ],
    );
  }
}

class _HouseInfoCard extends StatelessWidget {
  const _HouseInfoCard({required this.home});

  final CurrentHome home;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String value})>[
      (
        icon: Icons.meeting_room_outlined,
        label: '户型',
        value: home.roomType.isEmpty ? '--' : home.roomType,
      ),
      (
        icon: Icons.square_foot_rounded,
        label: '面积',
        value: home.area == null ? '--' : '${home.area}㎡',
      ),
      (
        icon: Icons.layers_outlined,
        label: '楼层',
        value: home.floor.isEmpty ? '--' : home.floor,
      ),
      (
        icon: Icons.explore_outlined,
        label: '朝向',
        value: home.orientation.isEmpty ? '--' : home.orientation,
      ),
    ];
    return _DetailSection(
      icon: Icons.apartment_rounded,
      title: '房屋信息',
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(item.icon, color: const Color(0xFF438AF4), size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.home});

  final CurrentHome home;

  @override
  Widget build(BuildContext context) {
    final hasLock = home.hasSmartLock;
    return _DetailSection(
      icon: hasLock ? Icons.lock_open_rounded : Icons.key_rounded,
      title: hasLock ? '智能门锁' : '入住服务',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasLock
                  ? const [Color(0xFFEAF3FF), Color(0xFFF5F9FF)]
                  : const [Color(0xFFF5F7FA), Color(0xFFFAFBFC)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: hasLock
                    ? const Color(0xFF438AF4)
                    : const Color(0xFF8B98AA),
                child: Icon(
                  hasLock ? Icons.bluetooth_rounded : Icons.support_agent,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLock ? '门锁已与当前租约绑定' : '该房间未绑定智能门锁',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLock ? '可使用蓝牙或租期密码开门' : '如需钥匙服务，请联系勿忧管家',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (hasLock) {
                    context.pushNamed(
                      RouteNames.tenantLockUnlock,
                      pathParameters: {'leaseId': home.leaseId},
                    );
                  } else {
                    context.pushNamed(RouteNames.customerServiceEnter);
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  minimumSize: const Size(0, 38),
                ),
                child: Text(hasLock ? '立即开锁' : '联系管家'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.children,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: const Color(0xFF347FF0), size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFEAEFF6)),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.sourceType});

  final String sourceType;

  @override
  Widget build(BuildContext context) {
    final normalized = sourceType.toUpperCase();
    final platform = normalized == 'PLATFORM';
    final landlord = normalized == 'LANDLORD';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: platform
            ? const Color(0xFFEAF3FF)
            : landlord
            ? const Color(0xFFE8FAF3)
            : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        platform
            ? '平台自营'
            : landlord
            ? '个人房源'
            : '租住房源',
        style: TextStyle(
          color: platform
              ? const Color(0xFF2875E8)
              : landlord
              ? const Color(0xFF078A66)
              : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F3F8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10285D9E),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Icon(icon, size: 19),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFD9FF), Color(0xFFEAF3FF)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 72,
          color: Color(0xFF5D95E8),
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home_work_outlined,
                size: 58,
                color: Color(0xFF88A9D8),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

String _date(DateTime? value) {
  return value == null ? '--' : DateFormat('yyyy.MM.dd').format(value);
}

String _yuan(int cents) {
  final amount = cents / 100;
  return amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
}
