/// 租客当前租约对应的 eKey 蓝牙开锁数据。
class TenantLockUnlockData {
  const TenantLockUnlockData({
    required this.leaseId,
    required this.smartLockId,
    required this.houseName,
    required this.roomName,
    required this.lockName,
    required this.lockMac,
    required this.lockData,
    required this.ttlockKeyId,
    this.ttlockLockId = 0,
    required this.startTime,
    required this.endTime,
    required this.permissionStatus,
    this.bluetoothUnlockAvailable = false,
    this.passcodeAvailable = false,
    this.passcodeStatus = '',
    this.passcodeStartTime = '',
    this.passcodeEndTime = '',
    this.leaseStatus = '',
    this.leaseValid = true,
    this.autoUnlockAvailable = false,
    this.autoUnlockMinRssi = -60,
    this.autoUnlockStableMillis = 2000,
    this.autoUnlockCooldownSeconds = 30,
  });

  /// 从后端标准响应的 data 节点解析租客开锁数据。
  factory TenantLockUnlockData.fromJson(Map<String, dynamic> json) {
    return TenantLockUnlockData(
      leaseId: _string(json['leaseId']),
      smartLockId: _string(json['smartLockId']),
      houseName: _string(json['houseName']),
      roomName: _string(json['roomName']),
      lockName: _string(json['lockName']),
      lockMac: _string(json['lockMac']),
      lockData: _string(json['lockData']),
      ttlockKeyId: _int(json['ttlockKeyId']),
      ttlockLockId: _int(json['ttlockLockId']),
      startTime: _string(json['startTime']),
      endTime: _string(json['endTime']),
      permissionStatus: _string(json['permissionStatus']),
      bluetoothUnlockAvailable: _bool(json['bluetoothUnlockAvailable']),
      passcodeAvailable: _bool(json['passcodeAvailable']),
      passcodeStatus: _string(json['passcodeStatus']),
      passcodeStartTime: _string(json['passcodeStartTime']),
      passcodeEndTime: _string(json['passcodeEndTime']),
      leaseStatus: _string(json['leaseStatus']),
      leaseValid: json['leaseValid'] is bool
          ? json['leaseValid'] as bool
          : true, // 字段缺失时默认有效（兼容旧接口）
      autoUnlockAvailable: _bool(json['autoUnlockAvailable']),
      autoUnlockMinRssi: _intOr(json['autoUnlockMinRssi'], -60),
      autoUnlockStableMillis: _intOr(json['autoUnlockStableMillis'], 2000),
      autoUnlockCooldownSeconds: _intOr(json['autoUnlockCooldownSeconds'], 30),
    );
  }

  final String leaseId;
  final String smartLockId;
  final String houseName;
  final String roomName;
  final String lockName;
  final String lockMac;
  final String lockData;
  final int ttlockKeyId;
  final int ttlockLockId;
  final String startTime;
  final String endTime;
  final String permissionStatus;
  final bool bluetoothUnlockAvailable;
  final bool passcodeAvailable;
  final String passcodeStatus;
  final String passcodeStartTime;
  final String passcodeEndTime;
  final String leaseStatus;
  final bool leaseValid;
  final bool autoUnlockAvailable;
  final int autoUnlockMinRssi;
  final int autoUnlockStableMillis;
  final int autoUnlockCooldownSeconds;

  bool get isActive => permissionStatus.toUpperCase() == 'ACTIVE';

  /// 租约是否已失效（退租/到期/取消等）
  bool get isLeaseInvalid =>
      leaseValid == false ||
      const [
        'TERMINATED',
        'EXPIRED',
        'CHECKED_OUT',
        'CANCELLED',
      ].contains(leaseStatus.toUpperCase());

  /// 仅在当前页面内更新 SDK 返回的新 lockData，不做持久化。
  TenantLockUnlockData copyWithLockData(String value) {
    return TenantLockUnlockData(
      leaseId: leaseId,
      smartLockId: smartLockId,
      houseName: houseName,
      roomName: roomName,
      lockName: lockName,
      lockMac: lockMac,
      lockData: value,
      ttlockKeyId: ttlockKeyId,
      ttlockLockId: ttlockLockId,
      startTime: startTime,
      endTime: endTime,
      permissionStatus: permissionStatus,
      bluetoothUnlockAvailable: bluetoothUnlockAvailable,
      passcodeAvailable: passcodeAvailable,
      passcodeStatus: passcodeStatus,
      passcodeStartTime: passcodeStartTime,
      passcodeEndTime: passcodeEndTime,
      leaseStatus: leaseStatus,
      leaseValid: leaseValid,
      autoUnlockAvailable: autoUnlockAvailable,
      autoUnlockMinRssi: autoUnlockMinRssi,
      autoUnlockStableMillis: autoUnlockStableMillis,
      autoUnlockCooldownSeconds: autoUnlockCooldownSeconds,
    );
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static int _int(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _intOr(Object? value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    return false;
  }
}

/// 开锁结果上报（手动蓝牙/无感自动共用）。严禁在该模型中包含 lockData、密码或 Token。
class UnlockRecordRequest {
  const UnlockRecordRequest({
    required this.smartLockId,
    required this.ttlockLockId,
    required this.triggerType,
    required this.result,
    required this.deviceInfo,
    required this.appVersion,
    this.rssi,
    this.stableMillis,
    this.failureReason,
  });

  final String smartLockId;
  final int ttlockLockId;
  final String triggerType;
  final int? rssi;
  final int? stableMillis;
  final String result;
  final String? failureReason;
  final String deviceInfo;
  final String appVersion;

  Map<String, dynamic> toJson() => {
    'smartLockId': smartLockId,
    'ttlockLockId': ttlockLockId,
    'triggerType': triggerType,
    'rssi': rssi,
    'stableMillis': stableMillis,
    'result': result,
    'failureReason': failureReason,
    'deviceInfo': deviceInfo,
    'appVersion': appVersion,
  };
}

/// 开门密码（由 GET/POST /leases/{leaseId}/lock/passcode 返回）。
class TenantPasscode {
  const TenantPasscode({
    required this.endTime,
    required this.firstUseNotice,
    required this.leaseId,
    required this.passcode,
    required this.passcodeType,
    required this.roomName,
    required this.smartLockId,
    required this.startTime,
    required this.status,
  });

  factory TenantPasscode.fromJson(Map<String, dynamic> json) {
    return TenantPasscode(
      endTime: _ps(json['endTime']),
      firstUseNotice: _ps(json['firstUseNotice']),
      leaseId: _ps(json['leaseId']),
      passcode: _ps(json['passcode']),
      passcodeType: _ps(json['passcodeType']),
      roomName: _ps(json['roomName']),
      smartLockId: _ps(json['smartLockId']),
      startTime: _ps(json['startTime']),
      status: _ps(json['status']),
    );
  }

  final String endTime;
  final String firstUseNotice;
  final String leaseId;
  final String passcode;
  final String passcodeType;
  final String roomName;
  final String smartLockId;
  final String startTime;
  final String status;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  static String _ps(Object? value) => value?.toString() ?? '';
}
