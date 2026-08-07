/// 当前租约房源信息
class CurrentHome {
  const CurrentHome({
    required this.houseId,
    this.title = '',
    required this.community,
    this.location = '',
    required this.building,
    required this.unit,
    required this.room,
    required this.leaseId,
    required this.leaseStatus,
    this.lockId,
    required this.lockStatus,
    this.address = '',
    this.coverImage = '',
    this.roomType = '',
    this.area,
    this.floor = '',
    this.orientation = '',
    this.monthlyRent,
    this.deposit,
    this.paymentMethod = '',
    this.leaseStartDate,
    this.leaseEndDate,
    this.sourceType = '',
  });

  factory CurrentHome.fromJson(Map<String, dynamic> json) {
    return CurrentHome(
      houseId: json['houseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      community: json['community'] as String? ?? '',
      location: json['location'] as String? ?? '',
      building: json['building'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      room: json['room'] as String? ?? '',
      leaseId: json['leaseId'] as String? ?? '',
      leaseStatus: json['leaseStatus'] as String? ?? '',
      lockId: json['lockId'] as String?,
      lockStatus: json['lockStatus'] as String? ?? 'unknown',
      address: json['address'] as String? ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      roomType: json['roomType'] as String? ?? '',
      area: (json['area'] as num?)?.toInt(),
      floor: json['floor'] as String? ?? '',
      orientation: json['orientation'] as String? ?? '',
      monthlyRent: (json['monthlyRent'] as num?)?.toInt(),
      deposit: (json['deposit'] as num?)?.toInt(),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      leaseStartDate: _parseDate(json['leaseStartDate']),
      leaseEndDate: _parseDate(json['leaseEndDate']),
      sourceType: json['sourceType'] as String? ?? '',
    );
  }

  final String houseId;
  final String title;
  final String community;
  final String location;
  final String building;
  final String unit;
  final String room;
  final String leaseId;
  final String leaseStatus;
  final String? lockId;
  final String lockStatus;
  final String address;
  final String coverImage;
  final String roomType;
  final int? area;
  final String floor;
  final String orientation;
  final int? monthlyRent;
  final int? deposit;
  final String paymentMethod;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final String sourceType;

  String get addressLabel => [
    if (building.isNotEmpty) '$building栋',
    if (unit.isNotEmpty) '$unit单元',
    room,
  ].where((e) => e.isNotEmpty).join('');

  String get displayTitle {
    if (title.isNotEmpty) return title;
    return [
      community,
      addressLabel,
    ].where((value) => value.isNotEmpty).join(' · ');
  }

  bool get hasSmartLock =>
      lockId?.trim().isNotEmpty == true &&
      !const {'UNBOUND', 'DELETED'}.contains(lockStatus.toUpperCase());

  static DateTime? _parseDate(dynamic value) {
    final text = value?.toString();
    return text == null || text.isEmpty ? null : DateTime.tryParse(text);
  }
}

class ProfileOverview {
  const ProfileOverview({
    required this.favoriteCount,
    required this.appointmentCount,
    required this.isVerified,
  });

  factory ProfileOverview.fromJson(Map<String, dynamic> json) {
    return ProfileOverview(
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      appointmentCount: (json['appointmentCount'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  final int favoriteCount;
  final int appointmentCount;
  final bool isVerified;
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
