import 'dart:convert';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/page_result.dart';
import '../domain/entities/house.dart';
import '../domain/house_search_state.dart';
import 'house_service.dart';

class HouseRepository {
  HouseRepository({
    required HouseService service,
    required LocalStorage localStorage,
  }) : _service = service,
       _localStorage = localStorage;

  static const pageSize = 20;
  static const maxHistoryCount = 10;

  final HouseService _service;
  final LocalStorage _localStorage;

  Future<PageResult<House>> search(HouseSearchState state) {
    return _service.fetchHouses(_buildQuery(state));
  }

  Future<List<String>> getSearchHistory() async {
    final raw = _localStorage.getString(StorageKeys.houseSearchHistory);
    if (raw == null || raw.isEmpty) return const [];

    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .take(maxHistoryCount)
          .toList(growable: false);
    } on FormatException {
      await clearSearchHistory();
      return const [];
    }
  }

  Future<List<String>> saveSearchKeyword(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return getSearchHistory();

    final history = (await getSearchHistory()).toList();
    history
      ..removeWhere((item) => item.toLowerCase() == normalized.toLowerCase())
      ..insert(0, normalized);
    final limited = history.take(maxHistoryCount).toList(growable: false);
    await _localStorage.setString(
      StorageKeys.houseSearchHistory,
      jsonEncode(limited),
    );
    return limited;
  }

  Future<void> clearSearchHistory() {
    return _localStorage.remove(StorageKeys.houseSearchHistory);
  }

  Future<List<String>> getHotKeywords() async {
    return const ['近地铁', '整租一居', '精装修', '可月付', '智能门锁', '拎包入住'];
  }

  Map<String, dynamic> _buildQuery(HouseSearchState state) {
    return <String, dynamic>{
      if (state.keyword.trim().isNotEmpty) 'keyword': state.keyword.trim(),
      if (state.category.isNotEmpty) 'category': state.category,
      if (state.region.isNotEmpty) 'region': state.region,
      if (state.minPrice > 0) 'minPrice': state.minPrice,
      if (state.maxPrice > 0) 'maxPrice': state.maxPrice,
      if (state.roomType.isNotEmpty) 'roomType': state.roomType,
      'sort': state.sort,
      'page': state.page,
      'pageSize': pageSize,
    };
  }
}
