class LandlordHouseItem {
  const LandlordHouseItem({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.imageUrls,
    required this.location,
    required this.communityId,
    required this.address,
    required this.price,
    required this.deposit,
    required this.paymentMethod,
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
    required this.viewCount,
    required this.favoriteCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LandlordHouseItem.fromJson(Map<String, dynamic> json) {
    return LandlordHouseItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      location: json['location']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      price: _int(json['price']),
      deposit: _int(json['deposit']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      rentType: json['rentType']?.toString() ?? '',
      roomType: json['roomType']?.toString() ?? '',
      area: _int(json['area']),
      floor: json['floor']?.toString() ?? '',
      orientation: json['orientation']?.toString() ?? '',
      decoration: json['decoration']?.toString() ?? '',
      availableDate: json['availableDate']?.toString() ?? '',
      metro: json['metro']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isSmartLockSupported: json['isSmartLockSupported'] == true,
      viewCount: _int(json['viewCount']),
      favoriteCount: _int(json['favoriteCount']),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  final String id;
  final String title;
  final String coverImage;
  final List<String> imageUrls;
  final String location;
  final String communityId;
  final String address;
  final int price;
  final int deposit;
  final String paymentMethod;
  final String rentType;
  final String roomType;
  final int area;
  final String floor;
  final String orientation;
  final String decoration;
  final String availableDate;
  final String metro;
  final String description;
  final String status;
  final bool isSmartLockSupported;
  final int viewCount;
  final int favoriteCount;
  final String createdAt;
  final String updatedAt;

  String get statusLabel {
    return switch (status) {
      'draft' => '草稿',
      'available' => '已上架',
      'offline' => '已下架',
      'reserved' => '已预定',
      'rented' => '已出租',
      _ => status,
    };
  }

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
}

class CreateHouseRequest {
  const CreateHouseRequest({
    required this.title,
    required this.coverImage,
    required this.imageUrls,
    required this.location,
    required this.communityId,
    required this.price,
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
    this.longitude,
    this.latitude,
    this.province,
    this.city,
    this.district,
  });

  final String title;
  final String coverImage;
  final List<String> imageUrls;
  final String location;
  final String communityId;
  final int price;
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
  final int? area;
  final String? floor;
  final String? orientation;
  final String? decoration;
  final String? availableDate;
  final String? metro;
  final String? description;
  final bool? isSmartLockSupported;
  final double? longitude;
  final double? latitude;
  final String? province;
  final String? city;
  final String? district;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'coverImage': coverImage,
      'imageUrls': imageUrls,
      'location': location,
      'communityId': communityId,
      'price': price,
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
    _put(map, 'longitude', longitude);
    _put(map, 'latitude', latitude);
    _put(map, 'province', province);
    _put(map, 'city', city);
    _put(map, 'district', district);
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
    this.longitude,
    this.latitude,
    this.province,
    this.city,
    this.district,
  });

  final String? title;
  final String? coverImage;
  final List<String>? imageUrls;
  final String? location;
  final String? communityId;
  final int? price;
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
  final int? area;
  final String? floor;
  final String? orientation;
  final String? decoration;
  final String? availableDate;
  final String? metro;
  final String? description;
  final bool? isSmartLockSupported;
  final double? longitude;
  final double? latitude;
  final String? province;
  final String? city;
  final String? district;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    _put(map, 'title', title);
    _put(map, 'coverImage', coverImage);
    if (imageUrls != null) map['imageUrls'] = imageUrls;
    _put(map, 'location', location);
    _put(map, 'communityId', communityId);
    _put(map, 'price', price);
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
    _put(map, 'longitude', longitude);
    _put(map, 'latitude', latitude);
    _put(map, 'province', province);
    _put(map, 'city', city);
    _put(map, 'district', district);
    return map;
  }

  void _put(Map<String, dynamic> map, String key, Object? value) {
    if (value != null) map[key] = value;
  }
}
