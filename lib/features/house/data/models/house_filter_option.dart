class HouseFilterOption {
  const HouseFilterOption({required this.label, required this.value});

  final String label;
  final String value;

  factory HouseFilterOption.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['label'] ?? '').toString();
    return HouseFilterOption(
      label: name,
      value: (json['value'] ?? name).toString(),
    );
  }

  factory HouseFilterOption.districtFromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    return HouseFilterOption(label: name, value: name);
  }
}
