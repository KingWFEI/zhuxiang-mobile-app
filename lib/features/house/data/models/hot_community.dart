class HotCommunity {
  const HotCommunity({
    required this.name,
    required this.district,
    required this.startingRent,
    required this.colorValue,
  });

  factory HotCommunity.fromJson(Map<String, dynamic> json) {
    return HotCommunity(
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      startingRent: json['startingRent'] as int? ?? 0,
      colorValue: json['colorValue'] as int? ?? 0,
    );
  }

  final String name;
  final String district;
  final int startingRent;
  final int colorValue;
}
