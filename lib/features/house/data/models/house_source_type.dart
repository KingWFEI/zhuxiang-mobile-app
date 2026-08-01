enum HouseSourceType {
  landlord('LANDLORD', '房东直租'),
  platform('PLATFORM', '平台自营');

  const HouseSourceType(this.value, this.label);

  final String value;
  final String label;

  bool get isPlatform => this == HouseSourceType.platform;

  factory HouseSourceType.fromJson(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'LANDLORD' => HouseSourceType.landlord,
      _ => HouseSourceType.platform,
    };
  }
}
