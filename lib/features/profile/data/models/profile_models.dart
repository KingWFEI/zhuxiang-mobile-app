/// 当前租约房源信息
class CurrentHome {
  const CurrentHome({
    required this.houseId,
    required this.community,
    required this.building,
    required this.unit,
    required this.room,
    required this.leaseId,
    required this.leaseStatus,
    this.lockId,
    required this.lockStatus,
    this.address = '',
  });

  factory CurrentHome.fromJson(Map<String, dynamic> json) {
    return CurrentHome(
      houseId: json['houseId'] as String? ?? '',
      community: json['community'] as String? ?? '',
      building: json['building'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      room: json['room'] as String? ?? '',
      leaseId: json['leaseId'] as String? ?? '',
      leaseStatus: json['leaseStatus'] as String? ?? '',
      lockId: json['lockId'] as String?,
      lockStatus: json['lockStatus'] as String? ?? 'unknown',
      address: json['address'] as String? ?? '',
    );
  }

  final String houseId;
  final String community;
  final String building;
  final String unit;
  final String room;
  final String leaseId;
  final String leaseStatus;
  final String? lockId;
  final String lockStatus;
  final String address;

  String get addressLabel => [
    if (building.isNotEmpty) '${building}栋',
    if (unit.isNotEmpty) '${unit}单元',
    room,
  ].where((e) => e.isNotEmpty).join('');
}

/// 门锁展示信息
class LockInfo {
  const LockInfo({
    required this.lockId,
    required this.lockName,
    required this.lockBrand,
    required this.lockStatus,
    required this.batteryLevel,
    required this.leaseId,
    required this.leaseStatus,
    this.startDate,
    this.endDate,
    this.permissionStatus,
    this.validFrom,
    this.validTo,
  });

  factory LockInfo.fromJson(Map<String, dynamic> json) {
    return LockInfo(
      lockId: json['lockId'] as String? ?? '',
      lockName: json['lockName'] as String? ?? '',
      lockBrand: json['lockBrand'] as String? ?? '',
      lockStatus: json['lockStatus'] as String? ?? 'unknown',
      batteryLevel: json['batteryLevel'] as int? ?? 0,
      leaseId: json['leaseId'] as String? ?? '',
      leaseStatus: json['leaseStatus'] as String? ?? '',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      permissionStatus: json['permissionStatus'] as String?,
      validFrom: json['validFrom'] as String?,
      validTo: json['validTo'] as String?,
    );
  }

  final String lockId;
  final String lockName;
  final String lockBrand;
  final String lockStatus;
  final int batteryLevel;
  final String leaseId;
  final String leaseStatus;
  final String? startDate;
  final String? endDate;
  final String? permissionStatus;
  final String? validFrom;
  final String? validTo;

  bool get isOnline => lockStatus == 'online';
  bool get isLowBattery => batteryLevel < 20;
  bool get hasPermission => permissionStatus?.toUpperCase() == 'ACTIVE';

  /// 当前租约是否已失效（退租/到期/取消等），失效时门锁卡片应隐藏。
  bool get isLeaseInvalidForLock {
    final status = (leaseStatus).toUpperCase();
    return const [
      'TERMINATED',
      'EXPIRED',
      'CHECKED_OUT',
      'CANCELLED',
    ].contains(status);
  }

  String get statusLabel {
    if (!isOnline) return '门锁离线';
    if (isLowBattery) return '电量不足';
    return '门锁已上锁';
  }
}
