import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/models/immersive_tour.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/api_client_provider.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/storage_service.dart';
import '../models/house_tag.dart';
import '../services/house_service.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  return StorageService.localStorage;
});

final houseServiceProvider = Provider<HouseService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HouseService(apiClient);
});

final locallyRentedHouseIdsProvider = StateProvider<Set<String>>((ref) {
  return const <String>{};
});

/// 获取房源详情信息（autoDispose 确保每次进入详情页都重新请求）
final houseDetailProvider =
    FutureProvider.autoDispose.family<ApiResult<HouseDetail>, String>((ref, houseId) async {
      final service = ref.watch(houseServiceProvider);
      return service.getHouseDetail(houseId);
    });

/// 房源快捷筛选标签（来自 GET /houses/tags）。
final houseTagsProvider = FutureProvider<List<HouseTag>>((ref) async {
  final service = ref.watch(houseServiceProvider);
  return service.fetchTags();
});

final immersiveTourAvailabilityProvider = FutureProvider.autoDispose
    .family<ApiResult<ImmersiveTourAvailability>, String>((ref, houseId) async {
      final service = ref.watch(houseServiceProvider);
      return service.getImmersiveTourAvailability(houseId);
    });

final immersiveTourProvider = FutureProvider.autoDispose
    .family<ApiResult<ImmersiveTour>, String>((ref, houseId) {
      final service = ref.watch(houseServiceProvider);
      return service.getImmersiveTour(houseId);
    });

/// 热门搜索关键词
final hotKeywordsProvider = Provider<List<String>>((ref) {
  return const ['近地铁', '整租', '两居室', '可月付', '智能门锁'];
});

/// 搜索历史管理
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
      SearchHistoryNotifier.new,
    );

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _maxHistoryCount = 10;

  @override
  List<String> build() {
    final raw = ref
        .read(localStorageProvider)
        .getString(StorageKeys.houseSearchHistory);
    if (raw == null || raw.isEmpty) {
      return const ['中央公园', '朝阳公园', '望京', '三里屯', '整租两居', '近地铁', '可月付', '智能门锁'];
    }
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .take(_maxHistoryCount)
          .toList(growable: false);
    } on FormatException {
      clearHistory();
      return const [];
    }
  }

  /// 保存关键词到搜索历史并返回更新后的列表
  Future<void> saveKeyword(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return;

    final history = state.toList();
    history
      ..removeWhere((item) => item.toLowerCase() == normalized.toLowerCase())
      ..insert(0, normalized);
    final limited = history.take(_maxHistoryCount).toList(growable: false);
    await ref
        .read(localStorageProvider)
        .setString(StorageKeys.houseSearchHistory, jsonEncode(limited));
    state = limited;
  }

  /// 清空所有搜索历史
  Future<void> clearHistory() async {
    await ref
        .read(localStorageProvider)
        .setString(StorageKeys.houseSearchHistory, '[]');
    state = const [];
  }
}
