/// 搜索发现页使用的热门小区摘要。
class HotCommunity {
  const HotCommunity({
    required this.name,
    required this.district,
    required this.startingRent,
    required this.colorValue,
  });

  final String name;
  final String district;
  final int startingRent;
  final int colorValue;
}
