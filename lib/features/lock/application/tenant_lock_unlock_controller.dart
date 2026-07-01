import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../staff/lock_initial/services/ttlock_ble_service.dart';
import '../data/models/tenant_lock_unlock_data.dart';
import '../data/repositories/tenant_lock_repository.dart';

enum TenantLockUnlockStage {
  loadingUnlockData,
  unlockDataLoaded,
  unlockDataFailed,
  scanning,
  matched,
  scanFailed,
  unlocking,
  unlockSuccess,
  unlockFailed,
}

class TenantLockUnlockState {
  const TenantLockUnlockState({
    this.stage = TenantLockUnlockStage.loadingUnlockData,
    this.unlockData,
    this.message,
    this.errorCode,
    this.targetMatched = false,
    this.requiresLogin = false,
    this.passcode,
    this.isLoadingPasscode = false,
    this.passcodeError,
    this.isRetryingPasscode = false,
  });

  final TenantLockUnlockStage stage;
  final TenantLockUnlockData? unlockData;
  final String? message;
  final String? errorCode;
  final bool targetMatched;
  final bool requiresLogin;
  final TenantPasscode? passcode;
  final bool isLoadingPasscode;
  final String? passcodeError;
  final bool isRetryingPasscode;

  bool get canUnlock =>
      targetMatched &&
      unlockData?.lockData.isNotEmpty == true &&
      (stage == TenantLockUnlockStage.matched ||
          stage == TenantLockUnlockStage.unlockFailed ||
          stage == TenantLockUnlockStage.unlockSuccess);

  TenantLockUnlockState copyWith({
    TenantLockUnlockStage? stage,
    TenantLockUnlockData? unlockData,
    String? message,
    String? errorCode,
    bool? targetMatched,
    bool? requiresLogin,
    TenantPasscode? passcode,
    bool? isLoadingPasscode,
    String? passcodeError,
    bool? isRetryingPasscode,
    bool clearPasscode = false,
    bool clearPasscodeError = false,
  }) {
    return TenantLockUnlockState(
      stage: stage ?? this.stage,
      unlockData: unlockData ?? this.unlockData,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      targetMatched: targetMatched ?? this.targetMatched,
      requiresLogin: requiresLogin ?? this.requiresLogin,
      passcode: clearPasscode ? null : passcode ?? this.passcode,
      isLoadingPasscode: isLoadingPasscode ?? this.isLoadingPasscode,
      passcodeError:
          clearPasscodeError ? null : passcodeError ?? this.passcodeError,
      isRetryingPasscode: isRetryingPasscode ?? this.isRetryingPasscode,
    );
  }
}

class TenantLockUnlockController extends StateNotifier<TenantLockUnlockState> {
  TenantLockUnlockController({
    required String leaseId,
    required TenantLockRepositoryContract repository,
    required TtlockBleServiceContract ttlockBleService,
    Duration scanTimeout = const Duration(seconds: 10),
  }) : _leaseId = leaseId,
       _repository = repository,
       _ttlockBleService = ttlockBleService,
       _scanTimeout = scanTimeout,
       super(const TenantLockUnlockState());

  final String _leaseId;
  final TenantLockRepositoryContract _repository;
  final TtlockBleServiceContract _ttlockBleService;
  final Duration _scanTimeout;

  Timer? _scanTimer;
  int _scanGeneration = 0;
  bool _targetHandled = false;
  bool _disposed = false;

  /// 获取租客 eKey 数据，成功且权限有效后自动开始蓝牙扫描。
  Future<void> load() async {
    if (_disposed) return;
    await _cancelCurrentScan();
    if (_disposed) return;

    state = state.copyWith(
      stage: TenantLockUnlockStage.loadingUnlockData,
      message: '正在获取门锁权限…',
      clearPasscode: true,
      clearPasscodeError: true,
    );

    if (_leaseId.trim().isEmpty) {
      state = state.copyWith(
        stage: TenantLockUnlockStage.unlockDataFailed,
        message: '租约信息无效',
      );
      return;
    }

    try {
      final data = await _repository.getUnlockData(_leaseId);
      if (_disposed) return;
      if (!data.isActive) {
        state = state.copyWith(
          stage: TenantLockUnlockStage.unlockDataFailed,
          unlockData: data,
          message: '门锁权限不可用',
        );
        return;
      }
      if (data.lockMac.trim().isEmpty || data.lockData.trim().isEmpty) {
        state = state.copyWith(
          stage: TenantLockUnlockStage.unlockDataFailed,
          unlockData: data,
          message: '门锁开锁数据不完整',
        );
        return;
      }

      state = state.copyWith(
        stage: TenantLockUnlockStage.unlockDataLoaded,
        unlockData: data,
        message: '门锁权限数据已获取',
      );
      if (data.passcodeAvailable &&
          data.passcodeStatus.toUpperCase() == 'ACTIVE') {
        unawaited(loadPasscode());
      }
      await startScan();
    } on Object catch (error) {
      if (_disposed) return;
      final failure = _mapUnlockDataError(error);
      state = state.copyWith(
        stage: TenantLockUnlockStage.unlockDataFailed,
        message: failure.message,
        errorCode: failure.errorCode,
        requiresLogin: failure.requiresLogin,
      );
    }
  }

  /// 请求权限并扫描目标 MAC，匹配后立即停止扫描。
  Future<void> startScan() async {
    final data = state.unlockData;
    if (_disposed || data == null || !data.isActive) return;

    await _cancelCurrentScan();
    if (_disposed) return;

    final generation = ++_scanGeneration;
    _targetHandled = false;
    state = state.copyWith(
      stage: TenantLockUnlockStage.scanning,
      unlockData: data,
      message: '正在搜索附近门锁，请靠近门锁',
    );

    try {
      final granted = await _ttlockBleService.requestBlePermissions();
      if (!_isCurrentScan(generation)) return;
      if (!granted) {
        state = state.copyWith(
          stage: TenantLockUnlockStage.scanFailed,
          unlockData: data,
          message: '请开启蓝牙和定位权限',
        );
        return;
      }

      await _ttlockBleService.init();
      if (!_isCurrentScan(generation)) return;

      await _ttlockBleService
          .startScanning(
            requestPermissions: false,
            onDeviceFound: (device) {
              if (!_isCurrentScan(generation) || _targetHandled) return;
              if (!_sameMac(device.mac, data.lockMac)) return;
              _targetHandled = true;
              unawaited(_handleMatchedDevice(generation, data));
            },
          )
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => throw TimeoutException('扫描启动超时'),
          );
      if (!_isCurrentScan(generation) || _targetHandled) return;

      _scanTimer = Timer(
        _scanTimeout,
        () => unawaited(_handleScanTimeout(generation, data)),
      );
      AppLoggerDebug.lock('租客门锁扫描已启动，目标 MAC：${data.lockMac}');
    } on Object catch (_) {
      if (!_isCurrentScan(generation)) return;
      await _stopScanningSilently();
      if (!_isCurrentScan(generation)) return;
      state = state.copyWith(
        stage: TenantLockUnlockStage.scanFailed,
        unlockData: data,
        message: '蓝牙扫描失败，请重试',
        errorCode: 'BLE_SCAN_ERROR',
      );
    }
  }

  /// 使用接口下发的租客 eKey lockData 执行蓝牙开锁。
  Future<void> unlock() async {
    final data = state.unlockData;
    if (_disposed || !state.targetMatched || data == null) return;
    if (data.lockData.trim().isEmpty) {
      state = state.copyWith(
        stage: TenantLockUnlockStage.unlockFailed,
        unlockData: data,
        targetMatched: true,
        message: '门锁开锁数据不可用',
      );
      return;
    }

    state = state.copyWith(
      stage: TenantLockUnlockStage.unlocking,
      unlockData: data,
      targetMatched: true,
      message: '正在开锁…',
    );

    try {
      await _ttlockBleService.init();
      final result = await _ttlockBleService.unlockByLockData(data.lockData);
      if (_disposed) return;

      if (result.success) {
        final nextLockData = result.lockData?.trim();
        state = state.copyWith(
          stage: TenantLockUnlockStage.unlockSuccess,
          unlockData: nextLockData == null || nextLockData.isEmpty
              ? data
              : data.copyWithLockData(nextLockData),
          targetMatched: true,
          message: '开锁成功',
        );
        return;
      }

      state = state.copyWith(
        stage: TenantLockUnlockStage.unlockFailed,
        unlockData: data,
        targetMatched: true,
        message: result.errorMessage?.trim().isNotEmpty == true
            ? result.errorMessage
            : '开锁失败，请靠近门锁后重试',
        errorCode: result.errorCode,
      );
    } on Object catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        stage: TenantLockUnlockStage.unlockFailed,
        unlockData: data,
        targetMatched: true,
        message: '开锁失败，请靠近门锁后重试',
        errorCode: 'BLE_UNLOCK_ERROR',
      );
    }
  }

  Future<void> _handleMatchedDevice(
    int generation,
    TenantLockUnlockData data,
  ) async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await _stopScanningSilently();
    if (!_isCurrentScan(generation)) return;
    AppLoggerDebug.lock('已匹配租客门锁，扫描立即停止');
    state = state.copyWith(
      stage: TenantLockUnlockStage.matched,
      unlockData: data,
      targetMatched: true,
      message: '已检测到当前房间门锁，可点击开锁',
    );
  }

  Future<void> _handleScanTimeout(
    int generation,
    TenantLockUnlockData data,
  ) async {
    if (!_isCurrentScan(generation) || _targetHandled) return;
    await _stopScanningSilently();
    if (!_isCurrentScan(generation)) return;
    state = state.copyWith(
      stage: TenantLockUnlockStage.scanFailed,
      unlockData: data,
      message: '未检测到当前门锁，请靠近门锁后重试',
    );
  }

  Future<void> _cancelCurrentScan() async {
    _scanGeneration++;
    _scanTimer?.cancel();
    _scanTimer = null;
    _targetHandled = false;
    await _stopScanningSilently();
  }

  Future<void> _stopScanningSilently() async {
    try {
      await _ttlockBleService.stopScanning();
    } on Object {
      // 页面退出和超时清理不应因 SDK 停止异常而中断。
    }
  }

  bool _isCurrentScan(int generation) =>
      !_disposed && generation == _scanGeneration;

  bool _sameMac(String first, String second) =>
      _normalizeMac(first) == _normalizeMac(second);

  String _normalizeMac(String value) =>
      value.replaceAll(RegExp('[^0-9a-fA-F]'), '').toUpperCase();

  _UnlockDataFailure _mapUnlockDataError(Object error) {
    if (error is ApiException) {
      return switch (error.statusCode) {
        401 => const _UnlockDataFailure(
          message: '登录已失效，请重新登录',
          errorCode: '401',
          requiresLogin: true,
        ),
        403 => const _UnlockDataFailure(message: '无门锁权限', errorCode: '403'),
        404 => const _UnlockDataFailure(message: '当前租约未绑定门锁', errorCode: '404'),
        _ => _UnlockDataFailure(
          message: error.message.isEmpty ? '暂无可用门锁权限' : error.message,
          errorCode: error.statusCode?.toString(),
        ),
      };
    }
    return const _UnlockDataFailure(message: '暂无可用门锁权限');
  }

  /// 获取当前租约期限线下开门密码。
  Future<void> loadPasscode() async {
    if (_disposed) return;
    state = state.copyWith(isLoadingPasscode: true, clearPasscodeError: true);

    try {
      final passcode = await _repository.getPasscode(_leaseId);
      if (_disposed) return;
      state = state.copyWith(
        passcode: passcode,
        isLoadingPasscode: false,
      );
      AppLoggerDebug.lock('开门密码获取成功');
    } on Object catch (error) {
      if (_disposed) return;
      final message =
          error is ApiException ? error.message : '获取开门密码失败';
      state = state.copyWith(
        isLoadingPasscode: false,
        passcodeError: message,
      );
    }
  }

  /// 重新生成当前租约期限开门密码（passcode 不可用时调用）。
  Future<void> retryPasscode() async {
    if (_disposed) return;
    state = state.copyWith(isRetryingPasscode: true, clearPasscodeError: true);

    try {
      final passcode = await _repository.retryPasscode(_leaseId);
      if (_disposed) return;
      state = state.copyWith(
        passcode: passcode,
        isRetryingPasscode: false,
      );
      AppLoggerDebug.lock('开门密码重新生成成功');
    } on Object catch (error) {
      if (_disposed) return;
      final message =
          error is ApiException ? error.message : '重新生成开门密码失败';
      state = state.copyWith(
        isRetryingPasscode: false,
        passcodeError: message,
      );
    }
  }

  /// 页面销毁时取消超时计时器并停止 TTLock 扫描。
  @override
  void dispose() {
    _disposed = true;
    _scanGeneration++;
    _scanTimer?.cancel();
    _scanTimer = null;
    unawaited(_stopScanningSilently());
    super.dispose();
  }
}

class _UnlockDataFailure {
  const _UnlockDataFailure({
    required this.message,
    this.errorCode,
    this.requiresLogin = false,
  });

  final String message;
  final String? errorCode;
  final bool requiresLogin;
}
