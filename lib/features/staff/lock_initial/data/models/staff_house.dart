class StaffHouse {
  const StaffHouse({
    required this.id,
    required this.title,
    required this.location,
    required this.communityId,
    required this.address,
    required this.building,
    required this.unit,
    required this.room,
    required this.isSmartLockSupported,
    required this.smartLockBound,
    required this.lockDevice,
  });

  final String id;
  final String title;
  final String location;
  final String communityId;
  final String address;
  final String building;
  final String unit;
  final String room;
  final bool isSmartLockSupported;
  final bool smartLockBound;
  final Map<String, dynamic>? lockDevice;

  bool get isSmartLockUnbound {
    return isSmartLockSupported && !smartLockBound && lockDevice == null;
  }

  String get roomLabel {
    return [
      if (building.isNotEmpty) building,
      if (unit.isNotEmpty) unit,
      if (room.isNotEmpty) room,
    ].join(' ');
  }

  String get searchText {
    return [
      id,
      title,
      location,
      communityId,
      address,
      building,
      unit,
      room,
    ].join(' ').toLowerCase();
  }

  factory StaffHouse.fromJson(Map<String, dynamic> json) {
    final lockDevice = json['lockDevice'];
    return StaffHouse(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      communityId: json['communityId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      building: json['building'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      room: json['room'] as String? ?? '',
      isSmartLockSupported: json['isSmartLockSupported'] as bool? ?? false,
      smartLockBound: json['smartLockBound'] as bool? ?? false,
      lockDevice: lockDevice is Map<String, dynamic> ? lockDevice : null,
    );
  }
}
