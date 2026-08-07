class LandlordHouseItem {
  const LandlordHouseItem({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.imageUrls,
    required this.facilityIds,
    required this.tagIds,
    required this.location,
    required this.communityId,
    required this.address,
    required this.price,
    required this.deposit,
    required this.paymentMethod,
    required this.rentMode,
    required this.rentType,
    required this.roomType,
    required this.area,
    required this.floor,
    required this.orientation,
    required this.decoration,
    required this.availableDate,
    required this.metro,
    required this.description,
    required this.status,
    required this.isSmartLockSupported,
    required this.isSelfViewingSupported,
    required this.viewCount,
    required this.favoriteCount,
    required this.createdAt,
    required this.updatedAt,
    this.communityName = '',
    this.building = '',
    this.unit = '',
    this.room = '',
    this.longitude,
    this.latitude,
    this.province = '',
    this.city = '',
    this.district = '',
    this.propertyCertificate,
  });

  factory LandlordHouseItem.fromJson(Map<String, dynamic> json) {
    return LandlordHouseItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      facilityIds: _dictionaryReferences(
        json['facilityIds'] ??
            json['facilities'] ??
            json['facilityList'] ??
            json['houseFacilities'],
        idKeys: const ['facilityId', 'id', 'value', 'code'],
        nameKeys: const ['facilityName', 'name', 'label', 'title'],
      ),
      tagIds: _dictionaryReferences(
        json['tagIds'] ?? json['tags'] ?? json['tagList'] ?? json['houseTags'],
        idKeys: const ['tagId', 'id', 'value', 'code'],
        nameKeys: const ['tagName', 'name', 'label', 'title'],
      ),
      location: json['location']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      communityName:
          json['communityName']?.toString() ??
          (json['community'] is Map
              ? (json['community'] as Map)['name']?.toString() ?? ''
              : ''),
      address: json['address']?.toString() ?? '',
      building: json['building']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      price: _int(json['price']),
      deposit: _int(json['deposit']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      rentMode: json['rentMode']?.toString() ?? 'WHOLE_RENT',
      rentType: json['rentType']?.toString() ?? '',
      roomType: json['roomType']?.toString() ?? '',
      area: _double(json['area']) ?? 0,
      floor: json['floor']?.toString() ?? '',
      orientation: json['orientation']?.toString() ?? '',
      decoration: json['decoration']?.toString() ?? '',
      availableDate: json['availableDate']?.toString() ?? '',
      metro: json['metro']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isSmartLockSupported: json['isSmartLockSupported'] == true,
      isSelfViewingSupported: json['isSelfViewingSupported'] == true,
      viewCount: _int(json['viewCount']),
      favoriteCount: _int(json['favoriteCount']),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      longitude: _double(json['longitude']),
      latitude: _double(json['latitude']),
      province: json['province']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      propertyCertificate: json['propertyCertificate'] is Map<String, dynamic>
          ? PropertyCertificateInfo.fromJson(
              json['propertyCertificate'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String id;
  final String title;
  final String coverImage;
  final List<String> imageUrls;
  final List<String> facilityIds;
  final List<String> tagIds;
  final String location;
  final String communityId;
  final String communityName;
  final String address;
  final String building;
  final String unit;
  final String room;
  final double? longitude;
  final double? latitude;
  final String province;
  final String city;
  final String district;
  final PropertyCertificateInfo? propertyCertificate;
  final int price;
  final int deposit;
  final String paymentMethod;
  final String rentMode;
  final String rentType;
  final String roomType;
  final double area;
  final String floor;
  final String orientation;
  final String decoration;
  final String availableDate;
  final String metro;
  final String description;
  final String status;
  final bool isSmartLockSupported;
  final bool isSelfViewingSupported;
  final int viewCount;
  final int favoriteCount;
  final String createdAt;
  final String updatedAt;

  String get statusLabel {
    return switch (status) {
      'draft' => '草稿',
      'available' => '已上架',
      'pendingReview' => '待审核',
      'rejected' => '审核驳回',
      'offline' => '已下架',
      'reserved' => '已预定',
      'rented' => '已出租',
      _ => status,
    };
  }

  bool get hasPropertyCertificate => propertyCertificate != null;
  bool get hasSubmittablePropertyCertificate =>
      propertyCertificate != null &&
      propertyCertificate!.auditStatus != 'rejected';

  String get priceYuan {
    final yuan = price / 100;
    return yuan == yuan.roundToDouble()
        ? yuan.toInt().toString()
        : yuan.toStringAsFixed(2);
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double? _double(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static List<String> _dictionaryReferences(
    dynamic value, {
    required List<String> idKeys,
    required List<String> nameKeys,
  }) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) {
            for (final key in [...idKeys, ...nameKeys]) {
              final reference = item[key]?.toString() ?? '';
              if (reference.isNotEmpty) return reference;
            }
            return '';
          }
          return item?.toString() ?? '';
        })
        .where((id) => id.isNotEmpty)
        .toList();
  }
}

class PropertyCertificateInfo {
  const PropertyCertificateInfo({
    required this.id,
    required this.originalName,
    required this.auditStatus,
    required this.createdAt,
    this.reviewRemark = '',
    this.submittedAt = '',
    this.reviewedAt = '',
  });

  factory PropertyCertificateInfo.fromJson(Map<String, dynamic> json) {
    return PropertyCertificateInfo(
      id: json['id']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      auditStatus: json['auditStatus']?.toString() ?? 'pending',
      reviewRemark: json['reviewRemark']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      submittedAt: json['submittedAt']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString() ?? '',
    );
  }

  final String id;
  final String originalName;
  final String auditStatus;
  final String reviewRemark;
  final String createdAt;
  final String submittedAt;
  final String reviewedAt;

  String get statusLabel {
    return switch (auditStatus) {
      'approved' => '已通过',
      'rejected' => '已驳回',
      _ => submittedAt.isEmpty ? '待提交' : '待审核',
    };
  }
}

class HouseDictionaryItem {
  const HouseDictionaryItem({
    required this.id,
    required this.name,
    this.icon = '',
  });

  factory HouseDictionaryItem.fromJson(Map<String, dynamic> json) {
    return HouseDictionaryItem(
      id:
          (json['id'] ??
                  json['facilityId'] ??
                  json['tagId'] ??
                  json['value'] ??
                  json['code'])
              ?.toString() ??
          '',
      name:
          (json['name'] ??
                  json['facilityName'] ??
                  json['tagName'] ??
                  json['label'] ??
                  json['title'])
              ?.toString() ??
          '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String icon;
}

class CreateHouseRequest {
  const CreateHouseRequest({
    required this.title,
    required this.coverImage,
    required this.imageUrls,
    required this.location,
    required this.communityId,
    required this.price,
    required this.rentMode,
    required this.rentType,
    required this.facilityIds,
    required this.tagIds,
    this.address,
    this.building,
    this.unit,
    this.room,
    this.deposit,
    this.paymentMethod,
    this.roomType,
    this.area,
    this.floor,
    this.orientation,
    this.decoration,
    this.availableDate,
    this.metro,
    this.description,
    this.isSmartLockSupported,
    this.isSelfViewingSupported,
  });

  final String title;
  final String coverImage;
  final List<String> imageUrls;
  final String location;
  final String communityId;
  final int price;
  final String rentMode;
  final String rentType;
  final List<String> facilityIds;
  final List<String> tagIds;
  final String? address;
  final String? building;
  final String? unit;
  final String? room;
  final int? deposit;
  final String? paymentMethod;
  final String? roomType;
  final double? area;
  final String? floor;
  final String? orientation;
  final String? decoration;
  final String? availableDate;
  final String? metro;
  final String? description;
  final bool? isSmartLockSupported;
  final bool? isSelfViewingSupported;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'coverImage': coverImage,
      'imageUrls': imageUrls,
      'location': location,
      'communityId': communityId,
      'price': price,
      'rentMode': rentMode,
      'rentType': rentType,
      'facilityIds': facilityIds,
      'tagIds': tagIds,
    };
    _put(map, 'address', address);
    _put(map, 'building', building);
    _put(map, 'unit', unit);
    _put(map, 'room', room);
    _put(map, 'deposit', deposit);
    _put(map, 'paymentMethod', paymentMethod);
    _put(map, 'roomType', roomType);
    _put(map, 'area', area);
    _put(map, 'floor', floor);
    _put(map, 'orientation', orientation);
    _put(map, 'decoration', decoration);
    _put(map, 'availableDate', availableDate);
    _put(map, 'metro', metro);
    _put(map, 'description', description);
    _put(map, 'isSmartLockSupported', isSmartLockSupported);
    _put(map, 'isSelfViewingSupported', isSelfViewingSupported);
    return map;
  }

  void _put(Map<String, dynamic> map, String key, Object? value) {
    if (value != null) map[key] = value;
  }
}

class UpdateHouseRequest {
  const UpdateHouseRequest({
    this.title,
    this.coverImage,
    this.imageUrls,
    this.location,
    this.communityId,
    this.price,
    this.rentMode,
    this.rentType,
    this.facilityIds,
    this.tagIds,
    this.address,
    this.building,
    this.unit,
    this.room,
    this.deposit,
    this.paymentMethod,
    this.roomType,
    this.area,
    this.floor,
    this.orientation,
    this.decoration,
    this.availableDate,
    this.metro,
    this.description,
    this.isSmartLockSupported,
    this.isSelfViewingSupported,
  });

  final String? title;
  final String? coverImage;
  final List<String>? imageUrls;
  final String? location;
  final String? communityId;
  final int? price;
  final String? rentMode;
  final String? rentType;
  final List<String>? facilityIds;
  final List<String>? tagIds;
  final String? address;
  final String? building;
  final String? unit;
  final String? room;
  final int? deposit;
  final String? paymentMethod;
  final String? roomType;
  final double? area;
  final String? floor;
  final String? orientation;
  final String? decoration;
  final String? availableDate;
  final String? metro;
  final String? description;
  final bool? isSmartLockSupported;
  final bool? isSelfViewingSupported;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    _put(map, 'title', title);
    _put(map, 'coverImage', coverImage);
    if (imageUrls != null) map['imageUrls'] = imageUrls;
    _put(map, 'location', location);
    _put(map, 'communityId', communityId);
    _put(map, 'price', price);
    _put(map, 'rentMode', rentMode);
    _put(map, 'rentType', rentType);
    if (facilityIds != null) map['facilityIds'] = facilityIds;
    if (tagIds != null) map['tagIds'] = tagIds;
    _put(map, 'address', address);
    _put(map, 'building', building);
    _put(map, 'unit', unit);
    _put(map, 'room', room);
    _put(map, 'deposit', deposit);
    _put(map, 'paymentMethod', paymentMethod);
    _put(map, 'roomType', roomType);
    _put(map, 'area', area);
    _put(map, 'floor', floor);
    _put(map, 'orientation', orientation);
    _put(map, 'decoration', decoration);
    _put(map, 'availableDate', availableDate);
    _put(map, 'metro', metro);
    _put(map, 'description', description);
    _put(map, 'isSmartLockSupported', isSmartLockSupported);
    _put(map, 'isSelfViewingSupported', isSelfViewingSupported);
    return map;
  }

  void _put(Map<String, dynamic> map, String key, Object? value) {
    if (value != null) map[key] = value;
  }
}
