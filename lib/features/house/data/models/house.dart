import 'house_source_type.dart';

/// 房源列表使用的数据模型。
class House {
  const House({
    required this.id,
    required this.title,
    required this.coverImage,
    this.images = const [],
    required this.location,
    required this.community,
    this.address = '',
    required this.price,
    this.deposit = 0,
    this.paymentMethod = '',
    required this.roomType,
    required this.area,
    required this.floor,
    required this.orientation,
    required this.tags,
    required this.facilities,
    required this.description,
    required this.isSmartLockSupported,
    required this.isFavorite,
    required this.metro,
    required this.decoration,
    required this.availableDate,
    this.landlordId = '',
    this.landlordName = '',
    this.sourceType = HouseSourceType.platform,
    this.avatarUrl = '',
    this.isVerified = false,
    this.rating = 0.0,
    this.rentedCount = 0,
    this.responseDescription = '',
    this.isRented = false,
    this.rentAvailability = '',
    this.activeOrderId = '',
    this.activeOrderBelongsToMe = false,
    this.status = '',
  });

  final String id;
  final String title;
  final String coverImage;
  final List<String> images;
  final String location;
  final String community;
  final String address;
  final int price;
  final int deposit;
  final String paymentMethod;
  final String roomType;
  final int area;
  final String floor;
  final String orientation;
  final List<String> tags;
  final List<String> facilities;
  final String description;
  final bool isSmartLockSupported;
  final bool isFavorite;
  final String metro;
  final String decoration;
  final String availableDate;
  final String landlordId;
  final String landlordName;
  final HouseSourceType sourceType;
  final String avatarUrl;
  final bool isVerified;
  final double rating;
  final int rentedCount;
  final String responseDescription;
  final bool isRented;
  final String rentAvailability;
  final String activeOrderId;
  final bool activeOrderBelongsToMe;
  final String status;

  bool get isRentLocked =>
      !isRented &&
      (rentAvailability.toLowerCase() == 'locked' ||
          rentAvailability.toLowerCase() == 'reserved' ||
          activeOrderId.isNotEmpty);

  bool get isPlatformSource => sourceType.isPlatform;
  String get sourceLabel => sourceType.label;

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      community: json['community'] as String? ?? '',
      address: json['address'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      deposit: json['deposit'] as int? ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      roomType: json['roomType'] as String? ?? '',
      area: json['area'] as int? ?? 0,
      floor: json['floor'] as String? ?? '',
      orientation: json['orientation'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      facilities:
          (json['facilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
      isSmartLockSupported: json['isSmartLockSupported'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      metro: json['metro'] as String? ?? '',
      decoration: json['decoration'] as String? ?? '',
      availableDate: json['availableDate'] as String? ?? '',
      landlordId: json['landlordId'] as String? ?? '',
      landlordName: json['landlordName'] as String? ?? '',
      sourceType: HouseSourceType.fromJson(json['sourceType']),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      rentedCount: json['rentedCount'] as int? ?? 0,
      responseDescription: json['responseDescription'] as String? ?? '',
      isRented: _parseRented(json),
      rentAvailability:
          '${json['rentAvailability'] ?? json['rent_availability'] ?? json['status'] ?? ''}',
      activeOrderId:
          '${json['activeOrderId'] ?? json['active_order_id'] ?? ''}',
      activeOrderBelongsToMe: _parseActiveOrderBelongsToMe(json),
      status: '${json['status'] ?? ''}',
    );
  }
}

bool _parseRented(Map<String, dynamic> json) {
  final direct = json['isRented'] ?? json['rented'] ?? json['leased'];
  if (direct is bool) return direct;

  final available = json['isAvailable'] ?? json['available'];
  if (available is bool) return !available;

  final leaseStatus = json['leaseStatus']?.toString().toLowerCase();
  if (leaseStatus == 'active') return true;

  final text = [
    json['status'],
    json['houseStatus'],
    json['rentStatus'],
    json['availabilityStatus'],
    json['availableStatus'],
  ].whereType<Object>().map((value) => value.toString().toLowerCase());

  if (text.any(
    const {
      'rented',
      'leased',
      'occupied',
      'unavailable',
      'inactive',
      'locked',
      '已出租',
      '已租',
      '出租中',
      '已入住',
      '不可租',
    }.contains,
  )) {
    return true;
  }

  final leaseId = json['leaseId'] ?? json['currentLeaseId'];
  return leaseId != null && leaseId.toString().trim().isNotEmpty;
}

bool _parseActiveOrderBelongsToMe(Map<String, dynamic> json) {
  final value =
      json['activeOrderBelongsToMe'] ??
      json['active_order_belongs_to_me'] ??
      json['lockedByMe'] ??
      json['locked_by_me'] ??
      json['hasMyActiveOrder'] ??
      json['has_my_active_order'];
  return value is bool && value;
}
