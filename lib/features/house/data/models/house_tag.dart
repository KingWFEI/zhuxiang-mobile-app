/// 房源快捷筛选标签，由 GET /houses/tags 返回。
class HouseTag {
  const HouseTag({required this.label, required this.value});

  final String label;
  final String value;

  factory HouseTag.fromJson(Map<String, dynamic> json) {
    return HouseTag(
      label: json['label'] as String? ?? '',
      value: (json['value'] ?? json['id'])?.toString() ?? '',
    );
  }
}
