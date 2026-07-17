class Community {
  const Community({
    required this.id,
    required this.name,
    this.address = '',
    this.province = '',
    this.city = '',
    this.district = '',
    this.longitude,
    this.latitude,
    this.externalPoiId = '',
    this.mapProvider = '',
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? longitude;
    double? latitude;
    if (location is Map) {
      longitude = _double(location['longitude'] ?? location['lng']);
      latitude = _double(location['latitude'] ?? location['lat']);
    } else if (location is String && location.contains(',')) {
      final parts = location.split(',');
      longitude = _double(parts.first);
      latitude = _double(parts.last);
    }

    return Community(
      id: _string(json['id'] ?? json['communityId']),
      name: _string(json['name'] ?? json['communityName'] ?? json['title']),
      address: _string(json['address'] ?? json['formattedAddress']),
      province: _string(json['province'] ?? json['pname']),
      city: _string(json['city'] ?? json['cityname']),
      district: _string(json['district'] ?? json['adname']),
      longitude: _double(json['longitude'] ?? json['lng']) ?? longitude,
      latitude: _double(json['latitude'] ?? json['lat']) ?? latitude,
      externalPoiId: _string(json['externalPoiId'] ?? json['poiId']),
      mapProvider: _string(json['mapProvider']),
    );
  }

  final String id;
  final String name;
  final String address;
  final String province;
  final String city;
  final String district;
  final double? longitude;
  final double? latitude;
  final String externalPoiId;
  final String mapProvider;

  String get regionLabel => [
    province,
    city,
    district,
  ].where((value) => value.isNotEmpty).toSet().join(' ');

  String get locationLabel {
    if (address.isNotEmpty) return address;
    return regionLabel;
  }

  static String _string(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).join('');
    return value?.toString() ?? '';
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class MapPoi {
  const MapPoi({
    required this.externalPoiId,
    required this.name,
    required this.longitude,
    required this.latitude,
    this.address = '',
    this.province = '',
    this.city = '',
    this.district = '',
  });

  factory MapPoi.fromJson(Map<String, dynamic> json) {
    return MapPoi(
      externalPoiId:
          json['externalPoiId']?.toString() ??
          json['poiId']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      longitude: _double(json['longitude'] ?? json['lng']),
      latitude: _double(json['latitude'] ?? json['lat']),
    );
  }

  final String externalPoiId;
  final String name;
  final String address;
  final String province;
  final String city;
  final String district;
  final double longitude;
  final double latitude;

  String get locationLabel =>
      [district, address].where((value) => value.isNotEmpty).join(' · ');

  Map<String, dynamic> toSelectionJson() => {
    'mapProvider': 'amap',
    'externalPoiId': externalPoiId,
  };

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
