import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/core/utils/app_logger.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../data/models/staff_house.dart';
import '../data/providers/lock_initialize_provider.dart';
import '../data/providers/staff_house_providers.dart';
import '../data/services/lock_api_service.dart';
import '../services/ttlock_ble_service.dart';

class LockManagePage extends ConsumerStatefulWidget {
  const LockManagePage({
    super.key,
    required this.smartLockId,
    required this.lockName,
    required this.lockMac,
    this.lockData = '',
  });

  final String smartLockId;
  final String lockName;
  final String lockMac;
  final String lockData;

  @override
  ConsumerState<LockManagePage> createState() => _LockManagePageState();
}

class _LockManagePageState extends ConsumerState<LockManagePage> {
  final _ttlockService = TtlockBleService();

  LockDetailResponse? _detail;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ref
          .read(lockApiServiceProvider)
          .getDetail(widget.smartLockId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('门锁管理')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('门锁管理')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败：${_error ?? '未知错误'}'),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: _loadDetail, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final d = _detail!;
    return Scaffold(
      appBar: AppBar(title: const Text('门锁管理')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _StatusCard(
            detail: d,
            unluckLoading: _actionLoading,
            onTestUnlock: () => _testUnlock(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BindRoomCard(
            detail: d,
            loading: _actionLoading,
            onBindRoom: () => _showHousePickerAndBind(),
            onUnbindRoom: () => _confirmUnbind(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _BleStatusCard(
            detail: d,
            loading: _actionLoading,
            onRefresh: _refreshBleStatus,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SyncPlatformCard(
            detail: d,
            loading: _actionLoading,
            onSync: () => _syncPlatform(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DangerZoneCard(
            loading: _actionLoading,
            onMarkReset: () => _confirmReset(),
          ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────

  Future<void> _testUnlock() async {
    // 1. 检查蓝牙权限
    final granted = await _ttlockService.requestBlePermissions();
    if (!granted) {
      _showSnackBar('请授予蓝牙权限后重试');
      return;
    }

    if (!mounted) return;
    setState(() => _actionLoading = true);

    try {
      // 2. 获取蓝牙开锁数据
      final unlockData = await ref
          .read(lockApiServiceProvider)
          .getUnlockData(widget.smartLockId);

      // 3. 初始化通通锁 SDK
      await _ttlockService.init();

      // 4. 调 SDK 开锁
      final result = await _ttlockService.unlockByLockData(unlockData.lockData);

      if (!mounted) return;

      if (result.success) {
        _showSnackBar('测试开锁成功');
      } else {
        _showSnackBar(
          '开锁失败：${result.errorMessage ?? result.errorCode ?? '未知错误'}',
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('开锁异常：$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showHousePickerAndBind() async {
    setState(() => _actionLoading = true);
    try {
      ref.invalidate(unboundSmartLockHousesProvider);
      await ref.read(unboundSmartLockHousesProvider.future);
    } catch (_) {
      // ignore fetch error, dialog will handle display
    }
    if (!mounted) return;
    setState(() => _actionLoading = false);

    StaffHouse? selected;
    await showDialog<StaffHouse?>(
      context: context,
      builder: (ctx) => _HousePickerDialog(
        onRefresh: () => ref.invalidate(unboundSmartLockHousesProvider),
      ),
    ).then((value) => selected = value);

    if (!mounted || selected == null) return;

    setState(() => _actionLoading = true);
    try {
      final result = await ref
          .read(lockInitializeProvider.notifier)
          .bindAndSync(smartLockId: widget.smartLockId, houseId: selected!.id);
      if (!mounted) return;
      if (result != null) {
        _showSnackBar('绑定成功，lockId：${result.lockId}');
        await _loadDetail();
      } else {
        final err = ref.read(lockInitializeProvider).errorMessage ?? '未知错误';
        _showSnackBar('绑定失败：$err');
      }
    } catch (e) {
      _showSnackBar('绑定失败：$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _confirmUnbind() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解除绑定'),
        content: const Text(
          '释放门锁后：\n'
          '1. 当前门锁将从该房间解绑；\n'
          '2. 已发放给租客的 eKey 将被回收；\n'
          '3. 已发放的密码需要通过网关或靠近门锁蓝牙删除；\n'
          '4. 门锁仍归本系统管理，可重新绑定其他房间。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('解除绑定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(lockApiServiceProvider).deleteBindRoom(widget.smartLockId);
      if (mounted) {
        _showSnackBar('已解除绑定');
        await _loadDetail();
      }
    } catch (e) {
      _showSnackBar('解除绑定失败：$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _refreshBleStatus() async {
    AppLoggerDebug.lock('开始蓝牙扫描刷新状态，目标 MAC：${widget.lockMac}');
    setState(() => _actionLoading = true);
    try {
      await _ttlockService.init();
      final completer = Completer<ScannedLockDevice?>();
      await _ttlockService.startScanning(
        onDeviceFound: (device) {
          if (device.mac == widget.lockMac) {
            completer.complete(device);
          }
        },
      );
      final device = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      await _ttlockService.stopScanning();
      if (device != null && mounted) {
        await ref
            .read(lockApiServiceProvider)
            .bleStatus(widget.smartLockId, device.battery, device.rssi);
        _showSnackBar('蓝牙状态已刷新');
        await _loadDetail();
      } else if (mounted) {
        _showSnackBar('未扫描到该门锁，请靠近门锁后重试');
      }
    } catch (e) {
      _showSnackBar('刷新失败：$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _syncPlatform() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(lockApiServiceProvider).syncPlatform(widget.smartLockId);
      if (mounted) {
        _showSnackBar('同步成功');
        await _loadDetail();
      }
    } catch (e) {
      if (mounted) {
        // 同步失败，回滚绑定
        try {
          await ref
              .read(lockApiServiceProvider)
              .deleteBindRoom(widget.smartLockId);
        } catch (_) {}
        _showSnackBar('同步失败：$e（已回滚绑定关系）');
        await _loadDetail();
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复出厂设置？'),
        content: const Text(
          '恢复出厂后：\n'
          '1. 当前门锁会回到未初始化状态\n'
          '2. 当前房间绑定关系将失效\n'
          '3. 云平台 lockId / keyId 将不可继续使用\n'
          '4. 后续需要重新初始化门锁\n\n'
          '操作步骤：\n'
          '1. 打开门锁电池仓\n'
          '2. 长按 Reset 按钮\n'
          '3. 根据语音提示输入 000#\n'
          '4. 听到恢复成功提示后返回 App',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '我已恢复出厂',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(lockApiServiceProvider).markReset(widget.smartLockId);
      if (mounted) {
        _showSnackBar('已标记为恢复出厂');
        context.pop();
      }
    } catch (e) {
      _showSnackBar('操作失败：$e');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─── 卡片组件 ──────────────────────────────────────────────────────

String _statusLabel(String s) => switch (s) {
  'INIT_LOCAL_SUCCESS' => '已初始化，待绑定房间',
  'ROOM_BOUND' => '已绑定房间，待同步云平台',
  'PLATFORM_FAILED' => '云平台同步失败',
  'BOUND' => '门锁可用',
  'RESET' => '已恢复出厂',
  _ => s,
};

Color _statusColor(String s) => switch (s) {
  'BOUND' => AppColors.success,
  'ROOM_BOUND' || 'PLATFORM_FAILED' => AppColors.warning,
  'RESET' => AppColors.textMuted,
  _ => AppColors.primary,
};

// ─── 1. 门锁状态卡片 ──────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.detail,
    required this.unluckLoading,
    required this.onTestUnlock,
  });
  final LockDetailResponse detail;
  final bool unluckLoading;
  final VoidCallback onTestUnlock;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.lock, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.lockName.isEmpty ? '未命名门锁' : detail.lockName,
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      'MAC：${detail.lockMac}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(detail.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  _statusLabel(detail.status),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _statusColor(detail.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (detail.createdAt != null) ...[
            const Divider(height: AppSpacing.xl),
            Text('初始化时间：${detail.createdAt}', style: AppTextStyles.bodySmall),
          ],
          const Divider(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: unluckLoading ? null : onTestUnlock,
            icon: unluckLoading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open, size: 18),
            label: const Text('测试蓝牙开锁'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. 绑定房间卡片 ──────────────────────────────────────────────

class _BindRoomCard extends StatelessWidget {
  const _BindRoomCard({
    required this.detail,
    required this.loading,
    required this.onBindRoom,
    required this.onUnbindRoom,
  });

  final LockDetailResponse detail;
  final bool loading;
  final VoidCallback onBindRoom;
  final VoidCallback onUnbindRoom;

  bool get _isBound => detail.houseId != null;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '绑定房间',
      child: _isBound ? _buildBound(context) : _buildUnbound(context),
    );
  }

  Widget _buildUnbound(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '当前门锁未绑定房间',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: loading ? null : onBindRoom,
          icon: const Icon(Icons.meeting_room, size: 18),
          label: const Text('去绑定房间'),
        ),
      ],
    );
  }

  Widget _buildBound(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.houseName != null && detail.houseName!.isNotEmpty)
          Text(detail.houseName!, style: AppTextStyles.bodyLarge),
        if (detail.roomName != null && detail.roomName!.isNotEmpty)
          Text(detail.roomName!, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: loading ? null : onUnbindRoom,
          icon: const Icon(Icons.link_off, size: 18),
          label: const Text('解除绑定'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
    );
  }
}

// ─── 3. 蓝牙状态卡片 ──────────────────────────────────────────────

class _BleStatusCard extends StatelessWidget {
  const _BleStatusCard({
    required this.detail,
    required this.loading,
    required this.onRefresh,
  });

  final LockDetailResponse detail;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '门锁状态',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: '电量',
            value: detail.battery != null ? '${detail.battery}%' : '--',
          ),
          _InfoRow(
            label: '信号',
            value: detail.rssi != null ? '${detail.rssi} dBm' : '--',
          ),
          _InfoRow(
            label: '来源',
            value: detail.batterySource == 'BLE_SCAN' ? '最近一次蓝牙扫描' : '--',
          ),
          if (detail.lastBleSyncTime != null)
            _InfoRow(label: '更新时间', value: detail.lastBleSyncTime!),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '* 普通蓝牙门锁不联网，此处为最近一次蓝牙扫描数据，非实时数据。',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth, size: 18),
            label: const Text('靠近门锁刷新状态'),
          ),
        ],
      ),
    );
  }
}

// ─── 4. 云平台同步卡片 ────────────────────────────────────────────

class _SyncPlatformCard extends StatelessWidget {
  const _SyncPlatformCard({
    required this.detail,
    required this.loading,
    required this.onSync,
  });

  final LockDetailResponse detail;
  final bool loading;
  final VoidCallback onSync;

  bool get _isSynced => detail.status == 'BOUND';
  bool get _canSync =>
      detail.status == 'ROOM_BOUND' || detail.status == 'PLATFORM_FAILED';

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '云平台同步',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isSynced) ...[
            _InfoRow(label: '状态', value: '已同步'),
            if (detail.lockId != null)
              _InfoRow(label: 'lockId', value: '${detail.lockId}'),
            if (detail.keyId != null)
              _InfoRow(label: 'keyId', value: '${detail.keyId}'),
          ] else if (detail.status == 'PLATFORM_FAILED') ...[
            Text(
              '状态：同步失败',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            if (detail.platformErrorMessage != null)
              Text(
                '原因：${detail.platformErrorMessage}',
                style: AppTextStyles.bodySmall,
              ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: loading ? null : onSync,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重试同步'),
            ),
          ] else if (_canSync) ...[
            const Text('状态：未同步', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: loading ? null : onSync,
              icon: const Icon(Icons.cloud_sync, size: 18),
              label: const Text('同步云平台'),
            ),
          ] else ...[
            Text(
              detail.status == 'INIT_LOCAL_SUCCESS'
                  ? '请先绑定房间后同步云平台'
                  : '当前状态不可同步',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 5. 危险操作卡片 ──────────────────────────────────────────────

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.loading, required this.onMarkReset});

  final bool loading;
  final VoidCallback onMarkReset;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '危险操作',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '恢复出厂后，当前门锁将回到未初始化状态，绑定关系和云平台数据将失效。',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: loading ? null : onMarkReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('恢复出厂设置'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ─── 房源选择弹窗 ──────────────────────────────────────────────────

class _HousePickerDialog extends ConsumerStatefulWidget {
  const _HousePickerDialog({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  ConsumerState<_HousePickerDialog> createState() => _HousePickerDialogState();
}

class _HousePickerDialogState extends ConsumerState<_HousePickerDialog> {
  StaffHouse? _selected;

  @override
  Widget build(BuildContext context) {
    final asyncHouses = ref.watch(unboundSmartLockHousesProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('选择房源')),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新',
            onPressed: () {
              widget.onRefresh();
              setState(() => _selected = null);
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: asyncHouses.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败：$error', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: widget.onRefresh,
                child: const Text('重试'),
              ),
            ],
          ),
          data: (houses) {
            if (houses.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('暂无未绑定门锁的房源', style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('刷新'),
                  ),
                ],
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: houses.length,
              itemBuilder: (_, i) {
                final h = houses[i];
                return ListTile(
                  selected: _selected?.id == h.id,
                  title: Text(h.title),
                  subtitle: Text(h.roomLabel),
                  onTap: () => setState(() => _selected = h),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selected != null
              ? () => Navigator.pop(context, _selected)
              : null,
          child: const Text('确认绑定'),
        ),
      ],
    );
  }
}

// ─── 通用组件 ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
