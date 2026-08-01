class HouseFacilityItem {
  const HouseFacilityItem({
    required this.id,
    required this.name,
    this.iconKey = '',
  });

  factory HouseFacilityItem.fromJson(Map<String, dynamic> json) {
    return HouseFacilityItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? '',
    );
  }

  factory HouseFacilityItem.fromName(String name) {
    return HouseFacilityItem(id: '', name: name);
  }

  final String id;
  final String name;
  final String iconKey;
}
