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
    required this.startTime,
    required this.endTime,
    required this.permissionStatus,
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
      startTime: _string(json['startTime']),
      endTime: _string(json['endTime']),
      permissionStatus: _string(json['permissionStatus']),
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
  final String startTime;
  final String endTime;
  final String permissionStatus;

  bool get isActive => permissionStatus.toUpperCase() == 'ACTIVE';

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
      startTime: startTime,
      endTime: endTime,
      permissionStatus: permissionStatus,
    );
  }

  static String _string(Object? value) => value?.toString() ?? '';

  static int _int(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
