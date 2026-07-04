import 'dart:async';

import 'package:ttlock_flutter/ttlock.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// TTLock 蓝牙能力接口，便于业务控制器复用并进行单元测试。
abstract interface class TtlockBleServiceContract {
  Future<void> init();

  Future<UnlockResult> unlockByLockData(String lockData);

  Future<void> startScanning({
    required void Function(ScannedLockDevice device) onDeviceFound,
    bool requestPermissions = true,
    Duration notifyInterval = const Duration(seconds: 1),
  });

  Future<void> stopScanning();

  Future<bool> requestBlePermissions();

  Future<bool> isBluetoothEnabled();
}

class TtlockBleService implements TtlockBleServiceContract {
  static const int _rssiChangeThreshold = 6;

  final Map<String, ScannedLockDevice> _lastNotifiedDevices = {};
  final Map<String, DateTime> _lastNotifiedAt = {};
  Duration _deviceNotifyInterval = const Duration(seconds: 1);

  @override
  Future<void> init() async {
    TTLock.printLog = false;
  }

  @override
  Future<UnlockResult> unlockByLockData(String lockData) async {
    final completer = Completer<UnlockResult>();

    TTLock.controlLock(
      lockData,
      TTControlAction.unlock,
      (lockTime, electricQuantity, uniqueId, newLockData) {
        completer.complete(
          UnlockResult.success(
            lockTime: lockTime,
            electricQuantity: electricQuantity,
            uniqueId: uniqueId,
            lockData: newLockData,
          ),
        );
      },
      (errorCode, errorMsg) {
        completer.complete(
          UnlockResult.failure(
            errorCode: errorCode.toString(),
            errorMessage: errorMsg,
          ),
        );
      },
    );

    return completer.future;
  }

  @override
  Future<void> startScanning({
    required void Function(ScannedLockDevice device) onDeviceFound,
    bool requestPermissions = true,
    Duration notifyInterval = const Duration(seconds: 1),
  }) async {
    final granted = !requestPermissions || await requestBlePermissions();

    if (!granted) {
      debugPrint('蓝牙扫描权限未授权');
      return;
    }
    _deviceNotifyInterval = notifyInterval;
    _resetScanCache();

    TTLock.startScanLock((scanModel) {
      final device = ScannedLockDevice.fromScanModel(scanModel);
      if (_shouldNotifyDevice(device)) {
        onDeviceFound(device);
      }
    });
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final completer = Completer<bool>();
    TTLock.getBluetoothState((state) {
      if (!completer.isCompleted) {
        completer.complete(state == TTBluetoothState.turnOn);
      }
    });
    return completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );
  }

  @override
  Future<void> stopScanning() async {
    TTLock.stopScanLock();
    _resetScanCache();
  }

  bool _shouldNotifyDevice(ScannedLockDevice device) {
    if (device.mac.isEmpty) return false;

    final now = DateTime.now();
    final lastDevice = _lastNotifiedDevices[device.mac];
    final lastNotifyAt = _lastNotifiedAt[device.mac];

    if (lastDevice == null || lastNotifyAt == null) {
      _recordNotifiedDevice(device, now);
      return true;
    }

    final elapsed = now.difference(lastNotifyAt);
    final hasMeaningfulChange =
        lastDevice.name != device.name ||
        lastDevice.battery != device.battery ||
        lastDevice.isInited != device.isInited ||
        lastDevice.isAllowUnlock != device.isAllowUnlock ||
        (lastDevice.rssi - device.rssi).abs() >= _rssiChangeThreshold;

    if (hasMeaningfulChange || elapsed >= _deviceNotifyInterval) {
      _recordNotifiedDevice(device, now);
      return true;
    }

    return false;
  }

  void _recordNotifiedDevice(ScannedLockDevice device, DateTime notifiedAt) {
    _lastNotifiedDevices[device.mac] = device;
    _lastNotifiedAt[device.mac] = notifiedAt;
  }

  void _resetScanCache() {
    _lastNotifiedDevices.clear();
    _lastNotifiedAt.clear();
  }

  /// 检查并申请蓝牙扫描所需权限
  ///
  /// Android 12 及以上需要：
  /// - bluetoothScan
  /// - bluetoothConnect
  /// - location
  ///
  /// Android 12 以下主要需要：
  /// - location
  @override
  Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final permissions = <Permission>[
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    final statuses = await permissions.request();

    final locationGranted = statuses[Permission.location]?.isGranted ?? false;
    final bluetoothScanGranted =
        statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final bluetoothConnectGranted =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;

    return locationGranted && bluetoothScanGranted && bluetoothConnectGranted;
  }

  // 根据锁数据初始化门锁
  Future<InitLockResult> initLock(ScannedLockDevice device) async {
    final completer = Completer<InitLockResult>();

    try {
      final scanMap = {
        'lockMac': device.rawScanModel.lockMac,
        'lockVersion': device.rawScanModel.lockVersion,
        'isInited': device.rawScanModel.isInited,
      };
      TTLock.initLock(
        scanMap,
        (lockData) {
          completer.complete(InitLockResult.success(lockData: lockData));
        },
        (errorCode, errorMsg) {
          completer.complete(
            InitLockResult.failure(
              errorCode: errorCode.toString(),
              errorMessage: errorMsg.toString(),
            ),
          );
        },
      );
    } catch (error) {
      completer.complete(
        InitLockResult.failure(
          errorCode: 'INIT_LOCK_EXCEPTION',
          errorMessage: error.toString(),
        ),
      );
    }

    return completer.future;
  }
}

class ScannedLockDevice {
  const ScannedLockDevice({
    required this.name,
    required this.mac,
    required this.rssi,
    required this.battery,
    required this.isInited,
    required this.isAllowUnlock,
    required this.rawScanModel,
  });

  final String name;
  final String mac;
  final int rssi;
  final int battery;
  final bool isInited;
  final bool isAllowUnlock;

  /// 通通锁 SDK 扫描返回的原始对象，初始化门锁时必须用它
  final TTLockScanModel rawScanModel;
  factory ScannedLockDevice.fromScanModel(TTLockScanModel model) {
    return ScannedLockDevice(
      name: model.lockName,
      mac: model.lockMac,
      rssi: model.rssi,
      battery: model.electricQuantity,
      isInited: model.isInited,
      isAllowUnlock: model.isAllowUnlock,
      rawScanModel: model,
    );
  }
}

class UnlockResult {
  UnlockResult({
    required this.success,
    this.lockTime,
    this.electricQuantity,
    this.lockData,
    this.uniqueId,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final int? lockTime;
  final int? electricQuantity;
  final int? uniqueId;
  final String? lockData;
  final String? errorCode;
  final String? errorMessage;

  factory UnlockResult.success({
    int? lockTime,
    int? electricQuantity,
    int? uniqueId,
    required String lockData,
  }) {
    return UnlockResult(
      success: true,
      lockTime: lockTime,
      electricQuantity: electricQuantity,
      uniqueId: uniqueId,
      lockData: lockData,
    );
  }

  factory UnlockResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return UnlockResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

class InitLockResult {
  const InitLockResult({
    required this.success,
    this.lockData,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final String? lockData;
  final String? errorCode;
  final String? errorMessage;

  factory InitLockResult.success({required String lockData}) {
    return InitLockResult(success: true, lockData: lockData);
  }

  factory InitLockResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return InitLockResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}
