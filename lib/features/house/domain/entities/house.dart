class House {
  const House({
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
  });

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
}
