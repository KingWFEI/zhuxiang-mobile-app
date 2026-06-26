import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zhuxiang_app/core/utils/app_logger.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/router/route_names.dart';
import '../data/providers/lock_initialize_provider.dart';
import '../data/providers/nearby_locks_provider.dart';
import '../data/services/lock_api_service.dart';
import '../services/ttlock_ble_service.dart';

class LockInitial extends ConsumerStatefulWidget {
  const LockInitial({super.key});

  @override
  ConsumerState<LockInitial> createState() => _LockInitialState();
}

class _LockInitialState extends ConsumerState<LockInitial> {
  final _ttlockService = TtlockBleService();

  Timer? _scanTimer;
  bool _foundLockInCurrentScan = false;

  /// 正在初始化的门锁 MAC
  String? _initializingMac;

  /// 初始化成功后的门锁信息
  _InitializedLockInfo? _initializedLock;

  /// 已初始化门锁的查询结果：MAC → (response | null=未录入 | absent=查询中)
  final Map<String, LockByMacResponse?> _initedLockResults = {};

  bool get _canScanLocks => !ref.read(nearbyLocksProvider).isScanning;

  @override
  void dispose() {
    _scanTimer?.cancel();
    unawaited(_ttlockService.stopScanning());
    ref.read(nearbyLocksProvider.notifier).onScanStopped();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyState = ref.watch(nearbyLocksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('门锁配置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _StatusPanel(
              resultCount: nearbyState.locks.length,
              isScanning: nearbyState.isScanning,
              hasInitSuccess: _initializedLock != null,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _canScanLocks ? _startScanLocks : null,
              icon: nearbyState.isScanning
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching, size: 18),
              label: Text(nearbyState.isScanning ? '正在搜索' : '开始搜索附近门锁'),
            ),
            if (nearbyState.locks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _NearbyLockList(
                locks: nearbyState.locks,
                initializingMac: _initializingMac,
                initedLockResults: _initedLockResults,
                initializedLock: _initializedLock,
                onInitializeLock: _confirmInitializeLock,
                onManageLock: _navigateToManageLock,
                onBindRoom: _navigateToManageAfterInit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmInitializeLock(ScannedLockDevice lock) async {
    AppLoggerDebug.lock('点击初始化门锁：${lock.name}，MAC：${lock.mac}');

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认初始化门锁'),
          content: Text(
            '确定要初始化这把门锁吗？\n\n'
            '门锁：${lock.name.isEmpty ? '未命名门锁' : lock.name}\n'
            'MAC：${lock.mac}\n'
            '信号：${lock.rssi} dBm',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认初始化'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _initializingMac = lock.mac);

    AppLoggerDebug.lock('开始调用 TTLock.initLock：${lock.name}，MAC：${lock.mac}');

    try {
      final result = await _ttlockService.initLock(lock);

      if (!mounted) return;

      if (!result.success) {
        AppLoggerDebug.lock(
          '门锁初始化失败：code=${result.errorCode}，message=${result.errorMessage}',
        );
        setState(() => _initializingMac = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '门锁初始化失败：${result.errorMessage ?? result.errorCode ?? '未知错误'}',
            ),
          ),
        );
        return;
      }

      final lockData = result.lockData;

      AppLoggerDebug.lock('门锁初始化成功：${lock.name}，MAC：${lock.mac}');
      AppLoggerDebug.lock('lockData：$lockData');

      final localResponse = await ref
          .read(lockInitializeProvider.notifier)
          .saveLocalInit(
            LockLocalInitRequest(
              lockName: lock.name,
              lockMac: lock.mac,
              lockData: lockData ?? '',
              rssi: lock.rssi,
              battery: lock.battery,
            ),
          );

      if (!mounted) return;

      if (localResponse == null) {
        final errMsg = ref.read(lockInitializeProvider).errorMessage ?? '未知错误';
        AppLoggerDebug.lock('保存初始化数据失败：$errMsg');
        setState(() => _initializingMac = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存门锁数据失败：$errMsg')));
        return;
      }

      setState(() {
        _initializingMac = null;
        _initializedLock = _InitializedLockInfo(
          lockName: lock.name,
          lockMac: lock.mac,
          lockData: lockData ?? '',
          rssi: lock.rssi,
          battery: lock.battery,
          smartLockId: localResponse.smartLockId,
        );
      });
    } catch (error) {
      if (!mounted) return;

      AppLoggerDebug.lock('门锁初始化异常：$error');
      setState(() => _initializingMac = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('门锁初始化异常：$error')));
    }
  }

  /// 扫描停止后自动查询已初始化门锁的后端记录
  void _autoQueryInitedLocks(List<ScannedLockDevice> locks) {
    for (final lock in locks) {
      if (!lock.isInited) continue;
      if (_initedLockResults.containsKey(lock.mac)) continue;

      _initedLockResults[lock.mac] = null; // 标记查询中（此时 key 存在但 value 尚未赋值完成）
      _queryLockByMac(lock);
    }
  }

  Future<void> _queryLockByMac(ScannedLockDevice lock) async {
    try {
      final response = await ref
          .read(lockApiServiceProvider)
          .getByMac(lock.mac);
      if (!mounted) return;
      setState(() => _initedLockResults[lock.mac] = response);
    } catch (_) {
      if (!mounted) return;
      setState(() => _initedLockResults[lock.mac] = null);
    }
  }

  void _navigateToManageLock(LockByMacResponse info) {
    context.pushNamed(
      RouteNames.staffLockManage,
      extra: {
        'smartLockId': info.smartLockId,
        'lockName': info.lockName,
        'lockMac': info.lockMac,
      },
    );
  }

  /// 初始化成功后直接进入管理页
  void _navigateToManageAfterInit() {
    final info = _initializedLock;
    if (info == null) return;
    context.pushNamed(
      RouteNames.staffLockManage,
      extra: {
        'smartLockId': info.smartLockId,
        'lockName': info.lockName,
        'lockMac': info.lockMac,
        'lockData': info.lockData,
      },
    );
  }

  Future<void> _startScanLocks() async {
    final scanNotifier = ref.read(nearbyLocksProvider.notifier);
    if (!_canScanLocks || ref.read(nearbyLocksProvider).isScanning) return;

    AppLoggerDebug.lock('开始扫描附近门锁');

    setState(() {
      _foundLockInCurrentScan = false;
      _initializingMac = null;
      _initializedLock = null;
      _initedLockResults.clear();
    });

    scanNotifier.onScanStarted();
    _scanTimer?.cancel();

    try {
      await _ttlockService.init();

      await Future.any([
        _ttlockService.startScanning(
          onDeviceFound: (device) {
            if (_foundLockInCurrentScan) return;
            _foundLockInCurrentScan = true;

            AppLoggerDebug.lock(
              '扫描到门锁：${device.name}，MAC：${device.mac}，信号：${device.rssi} dBm',
            );
            ref.read(nearbyLocksProvider.notifier).onDeviceFound(device);
            unawaited(_stopScanLocks());
          },
        ),
        Future.delayed(const Duration(seconds: 2), () {
          throw TimeoutException('扫描启动超时');
        }),
      ]);

      _scanTimer = Timer(const Duration(seconds: 2), () {
        AppLoggerDebug.lock('扫描时间结束，自动停止扫描');
        _stopScanLocks();
      });
    } catch (error) {
      _scanTimer?.cancel();
      scanNotifier.onScanStopped();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('扫描门锁失败：$error')));
    }
  }

  Future<void> _stopScanLocks() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    try {
      await _ttlockService.stopScanning();
    } catch (_) {}

    AppLoggerDebug.lock('扫描已停止');
    ref.read(nearbyLocksProvider.notifier).onScanStopped();

    // 扫描停止后，自动查询已初始化门锁的后端记录
    if (mounted) {
      _autoQueryInitedLocks(ref.read(nearbyLocksProvider).locks);
    }
  }
}

class _InitializedLockInfo {
  const _InitializedLockInfo({
    required this.lockName,
    required this.lockMac,
    required this.lockData,
    required this.rssi,
    required this.battery,
    required this.smartLockId,
  });

  final String lockName;
  final String lockMac;
  final String lockData;
  final int rssi;
  final int battery;
  final String smartLockId;
}

// ─── 组件 ──────────────────────────────────────────────────────────

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.resultCount,
    required this.isScanning,
    required this.hasInitSuccess,
  });

  final int resultCount;
  final bool isScanning;
  final bool hasInitSuccess;

  @override
  Widget build(BuildContext context) {
    final statusText = hasInitSuccess
        ? '门锁初始化成功，请绑定房间'
        : isScanning
        ? '正在搜索附近门锁'
        : resultCount > 0
        ? '已发现 $resultCount 个门锁'
        : '点击下方按钮搜索附近蓝牙门锁';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasInitSuccess ? AppColors.successLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: hasInitSuccess
                ? AppColors.success
                : AppColors.primary,
            child: Icon(
              hasInitSuccess ? Icons.check_circle_outline : Icons.lock_outline,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('门锁配置', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(statusText, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyLockList extends StatelessWidget {
  const _NearbyLockList({
    required this.locks,
    required this.initializingMac,
    required this.initedLockResults,
    required this.initializedLock,
    required this.onInitializeLock,
    required this.onManageLock,
    required this.onBindRoom,
  });

  final List<ScannedLockDevice> locks;
  final String? initializingMac;
  final Map<String, LockByMacResponse?> initedLockResults;
  final _InitializedLockInfo? initializedLock;
  final ValueChanged<ScannedLockDevice> onInitializeLock;
  final ValueChanged<LockByMacResponse> onManageLock;
  final VoidCallback onBindRoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text('附近门锁', style: AppTextStyles.titleMedium),
          ),
          for (final lock in locks) _buildLockTile(lock, context),
        ],
      ),
    );
  }

  Widget _buildLockTile(ScannedLockDevice lock, BuildContext context) {
    // 刚初始化成功的门锁 → 绿色绑定卡片
    if (initializedLock != null && lock.mac == initializedLock!.lockMac) {
      return _LockSuccessTile(
        lockName: initializedLock!.lockName,
        lockMac: initializedLock!.lockMac,
        rssi: initializedLock!.rssi,
        battery: initializedLock!.battery,
        onBindRoom: onBindRoom,
      );
    }

    // 正在初始化的门锁 → 加载中
    if (lock.mac == initializingMac) {
      return _LockLoadingTile(lock: lock, label: '初始化中...');
    }

    // 已初始化 → 自动查询结果
    if (lock.isInited) {
      if (!initedLockResults.containsKey(lock.mac)) {
        return _LockLoadingTile(lock: lock, label: '查询中...');
      }

      final result = initedLockResults[lock.mac];
      if (result == null) {
        // 未录入
        return _NearbyLockTile(
          lock: lock,
          trailing: Text(
            '未录入',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        );
      }

      // 已录入 → 管理门锁
      return _LockManageTile(
        lockName: result.lockName,
        lockMac: result.lockMac,
        status: result.status,
        houseName: result.houseName,
        roomName: result.roomName,
        onTap: () => onManageLock(result),
      );
    }

    // 未初始化 → 点击初始化
    return _NearbyLockTile(
      lock: lock,
      trailing: Text(
        '点击初始化',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => onInitializeLock(lock),
    );
  }
}

class _NearbyLockTile extends StatelessWidget {
  const _NearbyLockTile({
    required this.lock,
    required this.trailing,
    this.onTap,
  });

  final ScannedLockDevice lock;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.lock, color: AppColors.primary),
      ),
      title: Text(lock.name.isEmpty ? '未命名门锁' : lock.name),
      subtitle: Text(
        '${lock.mac}  信号 ${lock.rssi} dBm  ${lock.isInited ? '已初始化' : '未初始化'}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: trailing,
    );
  }
}

class _LockLoadingTile extends StatelessWidget {
  const _LockLoadingTile({required this.lock, required this.label});

  final ScannedLockDevice lock;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text(lock.name.isEmpty ? '未命名门锁' : lock.name),
      subtitle: Text(
        '${lock.mac}  信号 ${lock.rssi} dBm',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LockManageTile extends StatelessWidget {
  const _LockManageTile({
    required this.lockName,
    required this.lockMac,
    required this.status,
    this.houseName,
    this.roomName,
    required this.onTap,
  });

  final String lockName;
  final String lockMac;
  final String status;
  final String? houseName;
  final String? roomName;
  final VoidCallback onTap;

  String get _statusLabel => switch (status) {
    'BOUND' || 'PLATFORM_BOUND' => '已绑定',
    'ROOM_BOUND' || 'PLATFORM_FAILED' => '待同步',
    'INIT_LOCAL_SUCCESS' => '待绑定',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.successLight,
        child: const Icon(Icons.lock, color: AppColors.success),
      ),
      title: Text(lockName.isEmpty ? '未命名门锁' : lockName),
      subtitle: Text(
        '$lockMac  $_statusLabel${houseName != null ? ' · $houseName' : ''}${roomName != null ? ' $roomName' : ''}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        '管理门锁',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LockSuccessTile extends StatelessWidget {
  const _LockSuccessTile({
    required this.lockName,
    required this.lockMac,
    required this.rssi,
    required this.battery,
    required this.onBindRoom,
  });

  final String lockName;
  final String lockMac;
  final int rssi;
  final int battery;
  final VoidCallback onBindRoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('初始化成功', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lockName.isEmpty ? '未命名门锁' : lockName,
            style: AppTextStyles.bodyLarge,
          ),
          Text('MAC：$lockMac', style: AppTextStyles.bodySmall),
          Text(
            '信号：$rssi dBm  电量：${battery < 0 ? '--' : '$battery%'}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onBindRoom,
            icon: const Icon(Icons.meeting_room, size: 18),
            label: const Text('绑定房间'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
