import 'dart:async';

import 'package:ttlock_flutter/ttlock.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class TtlockBleService {
  Future<void> init() async {
    TTLock.printLog = true;
  }

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

  Future<void> startScanning({
    required void Function(ScannedLockDevice device) onDeviceFound,
  }) async {
    final granted = await requestBlePermissions();

    if (!granted) {
      debugPrint('蓝牙扫描权限未授权');
      return;
    }
    TTLock.startScanLock((scanModel) {
      onDeviceFound(ScannedLockDevice.fromScanModel(scanModel));
    });
  }

  Future<void> stopScanning() async {
    TTLock.stopScanLock();
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
}

class ScannedLockDevice {
  const ScannedLockDevice({
    required this.name,
    required this.mac,
    required this.rssi,
    required this.battery,
    required this.isInited,
    required this.isAllowUnlock,
  });

  final String name;
  final String mac;
  final int rssi;
  final int battery;
  final bool isInited;
  final bool isAllowUnlock;

  factory ScannedLockDevice.fromScanModel(TTLockScanModel model) {
    return ScannedLockDevice(
      name: model.lockName,
      mac: model.lockMac,
      rssi: model.rssi,
      battery: model.electricQuantity,
      isInited: model.isInited,
      isAllowUnlock: model.isAllowUnlock,
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
