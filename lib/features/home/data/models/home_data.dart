import '../../../house/data/models/house.dart';

class HomeData {
  final HomeHeaderData header;
  final int unreadMessageCount;
  final List<ServiceEntry> serviceEntries;
  final List<HomeTab> tabs;
  final Map<String, HomeHouseGroup> houseGroups;
  final List<HomeBanner>? advertisements;

  const HomeData({
    required this.header,
    required this.unreadMessageCount,
    required this.serviceEntries,
    required this.tabs,
    required this.houseGroups,
    this.advertisements,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      header: HomeHeaderData.fromJson(json['header'] as Map<String, dynamic>),
      unreadMessageCount: json['unreadMessageCount'] as int? ?? 0,
      serviceEntries:
          (json['serviceEntries'] as List<dynamic>?)
              ?.map((e) => ServiceEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tabs:
          (json['tabs'] as List<dynamic>?)
              ?.map((e) => HomeTab.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      houseGroups:
          (json['houseGroups'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              HomeHouseGroup.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      advertisements: (json['advertisements'] as List<dynamic>?)
          ?.map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HomeHeaderData {
  final String cityName;
  final String greeting;
  final String subtitle;
  final String searchPlaceholder;
  final String backgroundImageUrl;

  const HomeHeaderData({
    required this.cityName,
    required this.greeting,
    required this.subtitle,
    required this.searchPlaceholder,
    required this.backgroundImageUrl,
  });

  factory HomeHeaderData.fromJson(Map<String, dynamic> json) {
    return HomeHeaderData(
      cityName: json['cityName'] as String? ?? '',
      greeting: json['greeting'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      searchPlaceholder: json['searchPlaceholder'] as String? ?? '',
      backgroundImageUrl: json['backgroundImageUrl'] as String? ?? '',
    );
  }
}

class ServiceEntry {
  final String key;
  final String title;
  final String iconKey;
  final String targetType;
  final String targetValue;
  final bool requiresLogin;
  final bool enabled;

  const ServiceEntry({
    required this.key,
    required this.title,
    required this.iconKey,
    required this.targetType,
    required this.targetValue,
    required this.requiresLogin,
    required this.enabled,
  });

  factory ServiceEntry.fromJson(Map<String, dynamic> json) {
    return ServiceEntry(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetValue: json['targetValue'] as String? ?? '',
      requiresLogin: json['requiresLogin'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class HomeTab {
  final String key;
  final String title;
  final int sort;
  final bool enabled;

  const HomeTab({
    required this.key,
    required this.title,
    required this.sort,
    required this.enabled,
  });

  factory HomeTab.fromJson(Map<String, dynamic> json) {
    return HomeTab(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sort: json['sort'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class HomeHouseGroup {
  final List<HomeFeedItem> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  const HomeHouseGroup({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory HomeHouseGroup.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List<dynamic>?)
            ?.map((e) => HomeFeedItem.fromJson(e as Map<String, dynamic>))
            .where((item) => item.house?.isRented != true)
            .toList() ??
        [];

    return HomeHouseGroup(
      items: items,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class HomeFeedItem {
  final String type;
  final HomeHouseItem? house;
  final HomeAdItem? advertisement;

  const HomeFeedItem({required this.type, this.house, this.advertisement});

  factory HomeFeedItem.fromJson(Map<String, dynamic> json) {
    return HomeFeedItem(
      type: json['type'] as String? ?? '',
      house: json['house'] != null
          ? HomeHouseItem.fromJson(json['house'] as Map<String, dynamic>)
          : null,
      advertisement: json['advertisement'] != null
          ? HomeAdItem.fromJson(json['advertisement'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HomeHouseItem {
  final String id;
  final String title;
  final String coverImage;
  final String location;
  final String community;
  final int price;
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
  final bool isRented;

  const HomeHouseItem({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.location,
    required this.community,
    required this.price,
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
    this.isRented = false,
  });

  factory HomeHouseItem.fromJson(Map<String, dynamic> json) {
    return HomeHouseItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      location: json['location'] as String? ?? '',
      community: json['community'] as String? ?? '',
      price: json['price'] as int? ?? 0,
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
      isRented: _parseRented(json),
    );
  }

  House toHouse() {
    return House(
      id: id,
      title: title,
      coverImage: coverImage,
      location: location,
      community: community,
      price: price,
      roomType: roomType,
      area: area,
      floor: floor,
      orientation: orientation,
      tags: tags,
      facilities: facilities,
      description: description,
      isSmartLockSupported: isSmartLockSupported,
      isFavorite: isFavorite,
      metro: metro,
      decoration: decoration,
      availableDate: availableDate,
      isRented: isRented,
    );
  }

  static bool _parseRented(Map<String, dynamic> json) {
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
}

class HomeAdItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String targetType;
  final String targetValue;

  const HomeAdItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetType,
    required this.targetValue,
  });

  factory HomeAdItem.fromJson(Map<String, dynamic> json) {
    return HomeAdItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetValue: json['targetValue'] as String? ?? '',
    );
  }
}

class HomeBanner {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String position;
  final String targetType;
  final String targetValue;

  const HomeBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.position,
    required this.targetType,
    required this.targetValue,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      position: json['position'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetValue: json['targetValue'] as String? ?? '',
    );
  }
}
