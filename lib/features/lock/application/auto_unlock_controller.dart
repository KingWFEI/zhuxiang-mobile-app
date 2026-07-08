import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../../staff/lock_initial/services/ttlock_ble_service.dart';
import '../data/models/tenant_lock_unlock_data.dart';
import '../data/repositories/tenant_lock_repository.dart';

/// 无感开锁状态机。
///
/// 峰值策略：扫描到 RSSI ≥ 服务端下发的 [autoUnlockMinRssi] 即立即触发开锁，
/// 不再累积采样或判断信号稳定性。
enum AutoUnlockState {
  disabled,
  idle,
  checking,
  scanning,
  unlocking,
  success,
  failed,
  cooldown,
  stopped,
  blocked,
}

class AutoUnlockViewState {
  const AutoUnlockViewState({
    this.status = AutoUnlockState.disabled,
    this.enabled = false,
    this.message = '无感开锁未开启',
    this.cooldownRemaining = 0,
    this.lastRssi,
    this.targetSeen = false,
    this.consecutiveFailures = 0,
    this.triggerRssi,
  });

  final AutoUnlockState status;
  final bool enabled;
  final String message;
  final int cooldownRemaining;
  final int? lastRssi;
  final bool targetSeen;
  final int consecutiveFailures;

  /// 当前会话触发开锁的 RSSI 阈值（来自服务端 unlock-data）。
  final int? triggerRssi;

  AutoUnlockViewState copyWith({
    AutoUnlockState? status,
    bool? enabled,
    String? message,
    int? cooldownRemaining,
    int? lastRssi,
    bool? targetSeen,
    int? consecutiveFailures,
    int? triggerRssi,
    bool clearSignal = false,
  }) {
    return AutoUnlockViewState(
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      message: message ?? this.message,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      lastRssi: clearSignal ? null : lastRssi ?? this.lastRssi,
      targetSeen: targetSeen ?? this.targetSeen,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      triggerRssi: triggerRssi ?? this.triggerRssi,
    );
  }
}

abstract interface class AutoUnlockPreferenceStore {
  bool get enabled;
  Future<void> setEnabled(bool value);
}

class LocalAutoUnlockPreferenceStore implements AutoUnlockPreferenceStore {
  const LocalAutoUnlockPreferenceStore(this._storage);

  final LocalStorage _storage;

  @override
  bool get enabled => _storage.getBool(StorageKeys.autoUnlockEnabled) ?? false;

  @override
  Future<void> setEnabled(bool value) async {
    await _storage.setBool(StorageKeys.autoUnlockEnabled, value);
  }
}

abstract interface class AutoUnlockEnvironment {
  Future<int> batteryLevel();
  Future<String> deviceInfo();
  Future<String> appVersion();
}

class DeviceAutoUnlockEnvironment implements AutoUnlockEnvironment {
  DeviceAutoUnlockEnvironment({Battery? battery})
    : _battery = battery ?? Battery();

  final Battery _battery;

  @override
  Future<int> batteryLevel() => _battery.batteryLevel;

  @override
  Future<String> deviceInfo() async {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .trim();
  }

  @override
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }
}

class AutoUnlockController extends StateNotifier<AutoUnlockViewState> {
  AutoUnlockController({
    required String leaseId,
    required AutoUnlockRepositoryContract repository,
    required TtlockBleServiceContract bleService,
    required AutoUnlockPreferenceStore preferenceStore,
    required AutoUnlockEnvironment environment,
    this.consecutiveFailuresThreshold = 3,
    this.healthCheckInterval = const Duration(seconds: 10),
    this.scanNotifyInterval = const Duration(milliseconds: 200),
  }) : _leaseId = leaseId,
       _repository = repository,
       _bleService = bleService,
       _preferenceStore = preferenceStore,
       _environment = environment,
       super(const AutoUnlockViewState());

  final String _leaseId;
  final AutoUnlockRepositoryContract _repository;
  final TtlockBleServiceContract _bleService;
  final AutoUnlockPreferenceStore _preferenceStore;
  final AutoUnlockEnvironment _environment;

  /// 连续自动开锁失败达到此次数后暂停扫描。
  final int consecutiveFailuresThreshold;

  /// 定频检查电量和蓝牙状态的间隔。
  final Duration healthCheckInterval;

  /// BLE 扫描广播通知间隔（峰值策略下 200ms）。
  final Duration scanNotifyInterval;

  TenantLockUnlockData? _unlockData;
  Timer? _cooldownTimer;
  Timer? _healthTimer;
  int _generation = 0;
  bool _pageActive = true;
  bool _foreground = true;
  bool _disposed = false;
  bool _unlockInProgress = false;

  Future<void> initialize() async {
    if (_disposed) return;
    final enabled = _preferenceStore.enabled;
    state = state.copyWith(
      enabled: enabled,
      status: enabled ? AutoUnlockState.idle : AutoUnlockState.disabled,
      message: enabled ? '正在准备无感开锁' : '无感开锁未开启',
    );
    if (enabled) await _startFreshSession();
  }

  Future<void> enable() async {
    if (_disposed) return;
    await _preferenceStore.setEnabled(true);
    state = state.copyWith(
      enabled: true,
      status: AutoUnlockState.idle,
      message: '正在准备无感开锁',
      consecutiveFailures: 0,
    );
    await _startFreshSession();
  }

  Future<void> disable({bool clearPreference = true}) async {
    if (clearPreference) await _preferenceStore.setEnabled(false);
    await _stopSession(clearUnlockData: true);
    if (_disposed) return;
    state = const AutoUnlockViewState();
  }

  Future<void> onPageActiveChanged(bool active) async {
    _pageActive = active;
    if (!active) {
      await _stopForLifecycle('已离开门锁页面');
    } else if (state.enabled && _foreground) {
      await _startFreshSession();
    }
  }

  Future<void> onAppForegrounded() async {
    _foreground = true;
    if (state.enabled && _pageActive) {
      await _startFreshSession();
    }
  }

  Future<void> onAppBackgrounded() async {
    _foreground = false;
    await _stopForLifecycle('App 已进入后台，无感开锁已停止');
  }

  Future<void> _stopForLifecycle(String message) async {
    if (!state.enabled) return;
    await _stopSession(clearUnlockData: true);
    if (_disposed) return;
    state = state.copyWith(
      status: AutoUnlockState.stopped,
      message: message,
      cooldownRemaining: 0,
      clearSignal: true,
    );
  }

  Future<void> _startFreshSession() async {
    if (_disposed || !state.enabled || !_pageActive || !_foreground) return;
    await _stopSession(clearUnlockData: true);
    if (_disposed || !state.enabled || !_pageActive || !_foreground) return;

    final generation = ++_generation;
    state = state.copyWith(
      status: AutoUnlockState.checking,
      message: '正在检查蓝牙、权限和门锁状态',
      cooldownRemaining: 0,
      targetSeen: false,
      clearSignal: true,
    );

    try {
      final battery = await _environment.batteryLevel();
      if (!_isCurrent(generation)) return;
      if (battery < 15) {
        await _block('手机电量低于 15%，无感开锁已停止');
        return;
      }

      await _bleService.init();
      final bluetoothOn = await _bleService.isBluetoothEnabled();
      if (!_isCurrent(generation)) return;
      if (!bluetoothOn) {
        await _block('蓝牙未开启，请开启蓝牙后重新启用');
        return;
      }

      final granted = await _bleService.requestBlePermissions();
      if (!_isCurrent(generation)) return;
      if (!granted) {
        await _block('蓝牙或定位权限不足，请授权后重新启用');
        return;
      }

      final data = await _repository.getUnlockData(_leaseId);
      if (!_isCurrent(generation)) return;
      final validationMessage = _validateUnlockData(data);
      if (validationMessage != null) {
        await _block(validationMessage);
        return;
      }
      _unlockData = data;

      // 记录本次会话的触发阈值（来自服务端下发）。
      final triggerRssi = data.autoUnlockMinRssi == 0 ? -60 : data.autoUnlockMinRssi;
      state = state.copyWith(triggerRssi: triggerRssi);

      await _startScanning(generation);
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      if (_isAccountDisabled(error) || _isLeaseInvalidError(error)) {
        await _block(
          _isAccountDisabled(error)
              ? '账号已被禁用，无感开锁已关闭'
              : '当前租约已失效，无感开锁已关闭',
        );
      } else {
        await _stopBleOnly();
        if (_isCurrent(generation)) {
          state = state.copyWith(
            status: AutoUnlockState.blocked,
            message: '门锁校验失败，请稍后重试或使用手动开锁',
          );
        }
      }
    }
  }

  String? _validateUnlockData(TenantLockUnlockData data) {
    if (data.isLeaseInvalid || !data.isActive) return '当前租约已失效，无感开锁已关闭';
    if (!data.bluetoothUnlockAvailable) return '当前门锁不支持蓝牙开锁';
    if (!data.autoUnlockAvailable) return '当前门锁未开通无感开锁';
    if (data.lockMac.trim().isEmpty || data.lockData.trim().isEmpty) {
      return '门锁开锁数据不完整';
    }
    if (data.smartLockId.trim().isEmpty || data.ttlockLockId <= 0) {
      return '门锁身份数据不完整';
    }
    return null;
  }

  /// 启动 BLE 扫描，以 [scanNotifyInterval]（200ms）频率接收广播。
  Future<void> _startScanning(int generation) async {
    final data = _unlockData;
    if (!_isCurrent(generation) || data == null) return;
    _healthTimer?.cancel();
    _healthTimer = null;
    final triggerRssi = state.triggerRssi ?? -60;
    state = state.copyWith(
      status: AutoUnlockState.scanning,
      message: '扫描中，请靠近门锁（阈值 ${triggerRssi}dBm）',
      cooldownRemaining: 0,
      clearSignal: true,
    );
    try {
      await _bleService.startScanning(
        requestPermissions: false,
        notifyInterval: scanNotifyInterval,
        onDeviceFound: (device) {
          if (_isCurrent(generation)) _handleScan(device, data, generation);
        },
      );
      if (!_isCurrent(generation)) return;
      _healthTimer = Timer.periodic(
        healthCheckInterval,
        (_) => unawaited(_checkEnvironment(generation)),
      );
    } on Object {
      if (_isCurrent(generation)) {
        await _block('蓝牙扫描异常，请检查蓝牙状态后重新启用');
      }
    }
  }

  /// 峰值策略：RSSI ≥ 阈值 → 立即触发开锁，不累积采样。
  void _handleScan(
    ScannedLockDevice device,
    TenantLockUnlockData data,
    int generation,
  ) {
    if (!_isCurrent(generation) || _unlockInProgress) return;
    if (data.ttlockLockId <= 0 || !_sameMac(device.mac, data.lockMac)) return;

    final triggerRssi = state.triggerRssi ?? -60;

    state = state.copyWith(
      lastRssi: device.rssi,
      targetSeen: true,
    );

    if (device.rssi < triggerRssi) {
      state = state.copyWith(
        status: AutoUnlockState.scanning,
        message: '信号 $device.rssi dBm，未达阈值 $triggerRssi dBm',
      );
      return;
    }

    // RSSI 达到峰值阈值 → 立即触发开锁
    unawaited(_performUnlock(data, device.rssi, generation));
  }

  Future<void> _performUnlock(
    TenantLockUnlockData data,
    int rssi,
    int generation,
  ) async {
    if (!_isCurrent(generation) || _unlockInProgress) return;
    _unlockInProgress = true;
    await _stopBleOnly();
    if (!_isCurrent(generation)) {
      _unlockInProgress = false;
      return;
    }
    state = state.copyWith(status: AutoUnlockState.unlocking, message: '开锁中…');

    UnlockResult result;
    try {
      result = await _bleService.unlockByLockData(data.lockData);
    } on Object {
      result = UnlockResult.failure(
        errorCode: 'BLE_UNLOCK_ERROR',
        errorMessage: '蓝牙开锁异常',
      );
    }
    _unlockInProgress = false;
    if (!_isCurrent(generation)) return;

    if (result.success) {
      final rotated = result.lockData?.trim();
      if (rotated != null && rotated.isNotEmpty) {
        _unlockData = data.copyWithLockData(rotated);
      }
      state = state.copyWith(
        status: AutoUnlockState.success,
        message: '无感开锁成功',
        consecutiveFailures: 0,
      );
      _writeLocalResultLog(success: true, rssi: rssi);
      unawaited(
        _recordResult(data: data, success: true, rssi: rssi),
      );
      // 成功后使用服务端下发的冷却时间（后端配置 60s）。
      final seconds = data.autoUnlockCooldownSeconds > 0
          ? data.autoUnlockCooldownSeconds
          : 60;
      _startCooldown(Duration(seconds: seconds), generation);
      return;
    }

    // 开锁失败：不回退到冷却，立即重新扫描。
    final failures = state.consecutiveFailures + 1;
    final reason = _safeFailureReason(result.errorCode);
    state = state.copyWith(
      status: AutoUnlockState.failed,
      message: '无感开锁失败，重新扫描中',
      consecutiveFailures: failures,
    );
    _writeLocalResultLog(success: false, rssi: rssi, reason: reason);
    unawaited(
      _recordResult(
        data: data,
        success: false,
        rssi: rssi,
        failureReason: reason,
      ),
    );

    if (failures >= consecutiveFailuresThreshold) {
      await _block('连续开锁失败 $failures 次，无感开锁已暂停，请使用手动开锁');
      return;
    }

    // 立即重新扫描，不等待冷却。
    await _restartScanning(generation);
  }

  void _startCooldown(Duration duration, int generation) {
    _cooldownTimer?.cancel();
    var remaining = duration.inSeconds;
    state = state.copyWith(
      status: AutoUnlockState.cooldown,
      message: '冷却中',
      cooldownRemaining: remaining,
    );
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCurrent(generation) || !state.enabled) {
        timer.cancel();
        return;
      }
      remaining--;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          status: AutoUnlockState.idle,
          message: '准备重新扫描',
          cooldownRemaining: 0,
          clearSignal: true,
        );
        unawaited(_restartScanning(generation));
      } else {
        state = state.copyWith(cooldownRemaining: remaining);
      }
    });
  }

  Future<void> _restartScanning(int generation) async {
    if (!_isCurrent(generation) || _unlockData == null) return;
    final battery = await _environment.batteryLevel();
    if (!_isCurrent(generation)) return;
    if (battery < 15) {
      await _block('手机电量低于 15%，无感开锁已停止');
      return;
    }
    final bluetoothOn = await _bleService.isBluetoothEnabled();
    if (!_isCurrent(generation)) return;
    if (!bluetoothOn) {
      await _block('蓝牙已关闭，无感开锁已停止');
      return;
    }
    await _startScanning(generation);
  }

  Future<void> _checkEnvironment(int generation) async {
    if (!_isCurrent(generation) || state.status != AutoUnlockState.scanning) {
      return;
    }
    final battery = await _environment.batteryLevel();
    if (!_isCurrent(generation)) return;
    if (battery < 15) {
      await _block('手机电量低于 15%，无感开锁已停止');
      return;
    }
    final bluetoothOn = await _bleService.isBluetoothEnabled();
    if (_isCurrent(generation) && !bluetoothOn) {
      await _block('蓝牙已关闭，无感开锁已停止');
    }
  }

  Future<void> _recordResult({
    required TenantLockUnlockData data,
    required bool success,
    required int rssi,
    String? failureReason,
  }) async {
    try {
      final device = await _environment.deviceInfo();
      final version = await _environment.appVersion();
      await _repository.recordUnlock(
        _leaseId,
        UnlockRecordRequest(
          smartLockId: data.smartLockId,
          ttlockLockId: data.ttlockLockId,
          triggerType: 'AUTO_NEARBY',
          rssi: rssi,
          result: success ? 'SUCCESS' : 'FAILED',
          failureReason: failureReason,
          deviceInfo: device,
          appVersion: version,
        ),
      );
    } on Object catch (error) {
      AppLoggerDebug.warning('UNLOCK log upload failed');
      if (_isAccountDisabled(error) || _isLeaseInvalidError(error)) {
        await _block(
          _isAccountDisabled(error)
              ? '账号已被禁用，无感开锁已关闭'
              : '当前租约已失效，无感开锁已关闭',
        );
      }
    }
  }

  void _writeLocalResultLog({
    required bool success,
    required int rssi,
    String? reason,
  }) {
    final result = success ? 'SUCCESS' : 'FAILED';
    AppLoggerDebug.lock(
      'AUTO_UNLOCK result=$result rssi=$rssi'
      '${reason == null ? '' : ' reason=$reason'}',
    );
  }

  String _safeFailureReason(String? errorCode) {
    final normalized = errorCode?.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    return normalized == null || normalized.isEmpty
        ? 'BLE_UNLOCK_FAILED'
        : normalized;
  }

  Future<void> _block(String message) async {
    await _preferenceStore.setEnabled(false);
    await _stopSession(clearUnlockData: true);
    if (_disposed) return;
    state = state.copyWith(
      enabled: false,
      status: AutoUnlockState.blocked,
      message: message,
      cooldownRemaining: 0,
      clearSignal: true,
    );
  }

  Future<void> _stopSession({required bool clearUnlockData}) async {
    _generation++;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _healthTimer?.cancel();
    _healthTimer = null;
    _unlockInProgress = false;
    if (clearUnlockData) _unlockData = null;
    await _stopBleOnly();
  }

  Future<void> _stopBleOnly() async {
    try {
      await _bleService.stopScanning();
    } on Object {
      // 停止扫描失败不应阻断页面退出和安全清理。
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed &&
      generation == _generation &&
      state.enabled &&
      _pageActive &&
      _foreground;

  bool _sameMac(String first, String second) =>
      _normalizeMac(first) == _normalizeMac(second);

  String _normalizeMac(String value) =>
      value.replaceAll(RegExp('[^0-9a-fA-F]'), '').toUpperCase();

  bool _isAccountDisabled(Object error) =>
      error is ApiException &&
      error.message.toUpperCase().contains('ACCOUNT_DISABLED');

  bool _isLeaseInvalidError(Object error) =>
      error is ApiException &&
      (error.message.toUpperCase().contains('LEASE_INVALID') ||
          error.message.toUpperCase().contains('LEASE_EXPIRED'));

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cooldownTimer?.cancel();
    _healthTimer?.cancel();
    _unlockData = null;
    unawaited(_stopBleOnly());
    super.dispose();
  }
}
