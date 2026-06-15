import '../../../shared/models/page_result.dart';
import '../domain/entities/house.dart';
import '../domain/house_search_state.dart';

class HouseCache {
  final Map<String, PageResult<House>> _cache = {};

  PageResult<House>? get(HouseSearchState state) {
    return _cache[_buildKey(state)];
  }

  void set(HouseSearchState state, PageResult<House> data) {
    _cache[_buildKey(state)] = data;
  }

  void remove(HouseSearchState state) {
    _cache.remove(_buildKey(state));
  }

  void clear() {
    _cache.clear();
  }

  String _buildKey(HouseSearchState state) {
    return [
      state.keyword.trim().toLowerCase(),
      state.category,
      state.region,
      state.minPrice,
      state.maxPrice,
      state.roomType,
      state.sort,
      state.page,
    ].join('|');
  }
}
