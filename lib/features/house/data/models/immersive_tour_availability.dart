class ImmersiveTourAvailability {
  const ImmersiveTourAvailability({
    required this.available,
    this.tourId = '',
    this.coverImageUrl = '',
  });

  final bool available;
  final String tourId;
  final String coverImageUrl;

  factory ImmersiveTourAvailability.fromJson(Map<String, dynamic> json) {
    return ImmersiveTourAvailability(
      available: json['available'] as bool? ?? false,
      tourId: json['tourId'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
    );
  }
}
