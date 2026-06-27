import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../application/tenant_lock_unlock_controller.dart';
import '../../data/models/tenant_lock_unlock_data.dart';
import '../../data/providers/tenant_lock_providers.dart';

const _pageBackground = Color(0xFFF5F8FE);
const _brandBlue = Color(0xFF2778F6);
const _softBlue = Color(0xFFE9F2FF);
const _mutedText = Color(0xFF8C97AA);

class TenantLockUnlockPage extends ConsumerWidget {
  const TenantLockUnlockPage({required this.leaseId, super.key});

  final String leaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tenantLockUnlockProvider(leaseId);
    final state = ref.watch(provider);
    ref.listen(provider, (previous, next) {
      _showOperationToast(context, previous, next);
    });

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text(
          '蓝牙开锁',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showHelpSheet(context),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            label: const Text('帮助'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.only(right: AppSpacing.md),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F7FF), Color(0xFFFBFCFF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: state.unlockData == null
              ? _buildDataState(context, ref, state)
              : _buildUnlockContent(ref, state),
        ),
      ),
    );
  }

  /// 展示接口加载或接口异常状态。
  Widget _buildDataState(
    BuildContext context,
    WidgetRef ref,
    TenantLockUnlockState state,
  ) {
    final isLoading = state.stage == TenantLockUnlockStage.loadingUnlockData;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xl),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120E4A9B),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: isLoading ? _softBlue : const Color(0xFFFFF3E6),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(26),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.warning,
                      size: 36,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              state.message ?? '正在获取门锁权限…',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 156,
                height: 46,
                child: FilledButton(
                  onPressed: state.requiresLogin
                      ? () => _relogin(context, ref)
                      : () => ref
                            .read(tenantLockUnlockProvider(leaseId).notifier)
                            .load(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                  child: Text(state.requiresLogin ? '重新登录' : '重新获取'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 清理失效会话后进入登录页，避免已登录路由守卫将登录页重定向。
  Future<void> _relogin(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.goNamed(RouteNames.login);
  }

  /// 展示主开锁卡片、门锁信息和靠近提醒。
  Widget _buildUnlockContent(WidgetRef ref, TenantLockUnlockState state) {
    final data = state.unlockData!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        AppSpacing.xxl,
      ),
      children: [
        _UnlockHeroCard(
          data: data,
          state: state,
          onUnlock: state.canUnlock
              ? () => ref
                    .read(tenantLockUnlockProvider(leaseId).notifier)
                    .unlock()
              : null,
          onRescan: state.stage == TenantLockUnlockStage.scanFailed
              ? () => ref
                    .read(tenantLockUnlockProvider(leaseId).notifier)
                    .startScan()
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        _LockInfoCard(data: data),
        const SizedBox(height: AppSpacing.md),
        const _NearbyTipCard(),
      ],
    );
  }

  /// 展示蓝牙开锁帮助说明。
  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 42,
                child: Divider(thickness: 4, color: Color(0xFFD9E0EA)),
              ),
            ),
            SizedBox(height: 12),
            Text(
              '蓝牙开锁帮助',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 18),
            _HelpItem(index: '1', text: '打开手机蓝牙和定位权限'),
            _HelpItem(index: '2', text: '靠近当前房间门锁，建议保持在 2 米内'),
            _HelpItem(index: '3', text: '蓝牙匹配成功后点击开锁按钮'),
          ],
        ),
      ),
    );
  }

  /// 仅在开锁结果发生变化时显示统一提示，避免重建导致重复提示。
  void _showOperationToast(
    BuildContext context,
    TenantLockUnlockState? previous,
    TenantLockUnlockState next,
  ) {
    final changed =
        previous?.stage != next.stage || previous?.message != next.message;
    if (!changed || !context.mounted) return;

    if (next.stage == TenantLockUnlockStage.unlockSuccess) {
      AppToast.show(context, '开锁成功', type: AppToastType.success);
    } else if (next.stage == TenantLockUnlockStage.unlockFailed) {
      AppToast.show(context, _errorText(next), type: AppToastType.error);
    }
  }

  /// 拼接 SDK 错误信息和错误码。
  String _errorText(TenantLockUnlockState state) {
    final code = state.errorCode?.trim();
    if (code == null || code.isEmpty) {
      return state.message ?? '开锁失败，请靠近门锁后重试';
    }
    return '${state.message ?? '开锁失败'}（错误码：$code）';
  }
}

class _UnlockHeroCard extends StatelessWidget {
  const _UnlockHeroCard({
    required this.data,
    required this.state,
    required this.onUnlock,
    required this.onRescan,
  });

  final TenantLockUnlockData data;
  final TenantLockUnlockState state;
  final VoidCallback? onUnlock;
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 492,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140E4A9B),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _HeroBackground()),
          const Positioned(
            top: 14,
            right: -18,
            width: 148,
            height: 232,
            child: _LockArtwork(),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 92),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF5C7FB5),
                          size: 30,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            data.roomName.isEmpty ? '当前房间' : data.roomName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF121C2E),
                              fontSize: 23,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BluetoothStatus(state: state),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 250,
                    child: Text(
                      state.message ?? '请靠近当前房间门锁',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: _UnlockButton(state: state, onPressed: onUnlock),
                  ),
                  const Spacer(),
                  if (onRescan != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: onRescan,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('重新搜索门锁'),
                        style: TextButton.styleFrom(
                          foregroundColor: _brandBlue,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        data.houseName.isEmpty ? '住享智能门锁' : data.houseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9AA7BA),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BuildingLinePainter(),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF4F8FF)],
            stops: [0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _BuildingLinePainter extends CustomPainter {
  /// 绘制参考图中的浅蓝建筑线稿，避免抢占主要操作信息。
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x1F4C91F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()..color = const Color(0x0D4C91F7);
    final left = size.width * 0.61;
    final top = 30.0;
    final building = Rect.fromLTWH(left, top, size.width * 0.34, 205);
    canvas.drawRect(building, fillPaint);
    canvas.drawRect(building, linePaint);

    const columns = 3;
    const rows = 5;
    final windowWidth = building.width / 7;
    final windowHeight = building.height / 12;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final window = Rect.fromLTWH(
          building.left + 14 + column * (windowWidth + 10),
          building.top + 18 + row * (windowHeight + 13),
          windowWidth,
          windowHeight,
        );
        canvas.drawRect(window, linePaint);
      }
    }
    canvas.drawLine(
      Offset(left - 38, building.bottom),
      Offset(size.width, building.bottom),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockArtwork extends StatelessWidget {
  const _LockArtwork();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.white, Colors.white],
        stops: [0, 0.22, 1],
      ).createShader(bounds),
      child: Image.asset(
        'assets/lock_style.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _BluetoothStatus extends StatelessWidget {
  const _BluetoothStatus({required this.state});

  final TenantLockUnlockState state;

  @override
  Widget build(BuildContext context) {
    final matched = state.targetMatched;
    final failed = state.stage == TenantLockUnlockStage.scanFailed;
    final color = failed ? AppColors.warning : _brandBlue;
    final label = matched
        ? '蓝牙已自动连接'
        : failed
        ? '未检测到门锁'
        : '正在搜索蓝牙';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.bluetooth, color: Colors.white, size: 16),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (matched) ...[
          const _SignalBars(),
          const Text(
            '信号稳定',
            style: TextStyle(color: Color(0xFF53647E), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          4,
          (index) => Container(
            width: 2.5,
            height: 4.0 + index * 3,
            decoration: BoxDecoration(
              color: const Color(0xFF5577AD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.state, required this.onPressed});

  final TenantLockUnlockState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isUnlocking = state.stage == TenantLockUnlockStage.unlocking;
    final success = state.stage == TenantLockUnlockStage.unlockSuccess;
    final enabled = onPressed != null && !isUnlocking;
    final label = switch (state.stage) {
      TenantLockUnlockStage.unlocking => '正在开锁',
      TenantLockUnlockStage.unlockSuccess => '再次开锁',
      TenantLockUnlockStage.unlockFailed when state.targetMatched => '再次开锁',
      _ when state.targetMatched => '点击开锁',
      _ => '等待匹配',
    };
    final activeColor = success ? AppColors.success : _brandBlue;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 214,
          height: 214,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Ring(size: 214, color: activeColor.withValues(alpha: 0.10)),
              _Ring(size: 178, color: activeColor.withValues(alpha: 0.14)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 146,
                height: 146,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: enabled || isUnlocking
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            success
                                ? const Color(0xFF45C988)
                                : const Color(0xFF4C91FF),
                            activeColor,
                          ],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFB9C5D5), Color(0xFF9EABBC)],
                        ),
                  border: Border.all(color: Colors.white, width: 7),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(
                        alpha: enabled ? 0.28 : 0.10,
                      ),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUnlocking)
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        success
                            ? Icons.check_circle_rounded
                            : Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
    );
  }
}

class _LockInfoCard extends StatelessWidget {
  const _LockInfoCard({required this.data});

  final TenantLockUnlockData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0E4A9B),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '门锁信息',
            style: TextStyle(
              color: Color(0xFF202B3D),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoMetric(
                  icon: Icons.lock_outline_rounded,
                  iconColor: _brandBlue,
                  label: '门锁名称',
                  value: data.lockName,
                ),
              ),
              const SizedBox(
                height: 52,
                child: VerticalDivider(color: Color(0xFFE7ECF3)),
              ),
              Expanded(
                child: _InfoMetric(
                  icon: Icons.bluetooth_connected_rounded,
                  iconColor: AppColors.success,
                  label: '门锁 MAC',
                  value: data.lockMac,
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Color(0xFFE7ECF3)),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: _brandBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'eKey 有效期',
                      style: TextStyle(color: _mutedText, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _validPeriod(data),
                      style: const TextStyle(
                        color: Color(0xFF253147),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  /// 将后端时间压缩为适合信息卡展示的日期区间。
  String _validPeriod(TenantLockUnlockData data) {
    String compact(String value) {
      final date = value.trim().split(' ').first;
      return date.replaceAll('-', '.');
    }

    final start = compact(data.startTime);
    final end = compact(data.endTime);
    if (start.isEmpty && end.isEmpty) return '--';
    return '$start  -  $end';
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _mutedText, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? '--' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF253147),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NearbyTipCard extends StatelessWidget {
  const _NearbyTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7F6)),
      ),
      child: const Row(
        children: [
          _TipIcon(),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '靠近门锁时将自动连接蓝牙',
                  style: TextStyle(
                    color: Color(0xFF253147),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '请保持手机蓝牙开启，确保顺畅开门',
                  style: TextStyle(color: _mutedText, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipIcon extends StatelessWidget {
  const _TipIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: _softBlue, shape: BoxShape.circle),
      child: const Icon(
        Icons.lightbulb_outline_rounded,
        color: _brandBlue,
        size: 23,
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _softBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: const TextStyle(
                color: _brandBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF344155), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
