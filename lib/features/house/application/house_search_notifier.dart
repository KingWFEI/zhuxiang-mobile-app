import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/page_result.dart';
import '../data/models/house.dart';
import '../data/models/house_search_state.dart';
import '../data/providers/house_providers.dart';

/// 房源搜索
final houseSearchProvider =
    NotifierProvider<HouseSearchNotifier, HouseSearchState>(
  HouseSearchNotifier.new,
);

/// 房源搜索状态管理
class HouseSearchNotifier extends Notifier<HouseSearchState> {
  static const _pageSize = 20;

  Timer? _debounceTimer;
  int _requestVersion = 0;

  @override
  HouseSearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const HouseSearchState();
  }

  /// 初始化：加载搜索历史和热门关键词，随后执行一次默认搜索。
  Future<void> initialize() async {
    await Future.wait([loadSearchHistory(), loadHotKeywords()]);
    await search();
  }

  /// 更新搜索关键词，300ms 防抖后自动发起搜索。
  void updateKeyword(String keyword) {
    _requestVersion++;
    state = state.copyWith(keyword: keyword, clearError: true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), search);
  }

  /// 切换租赁类型（整租/月租等），直接发起搜索。
  void updateCategory(String category) {
    if (category == state.category) return;
    _debounceTimer?.cancel();
    state = state.copyWith(category: category, clearError: true);
    unawaited(search());
  }

  /// 批量更新筛选条件（区域、价格、户型、排序）并重新搜索。
  void updateFilter({
    required String region,
    required int minPrice,
    required int maxPrice,
    required String roomType,
    required String sort,
  }) {
    _debounceTimer?.cancel();
    state = state.copyWith(
      region: region,
      minPrice: minPrice,
      maxPrice: maxPrice,
      roomType: roomType,
      sort: sort,
      clearError: true,
    );
    unawaited(search());
  }

  /// 发起搜索请求，支持 forceRefresh 强制刷新。
  Future<void> search({bool forceRefresh = false}) async {
    final queryState = state.copyWith(page: 1);
    final requestVersion = ++_requestVersion;

    state = state.copyWith(
      page: 1,
      isLoading: !forceRefresh,
      isRefreshing: forceRefresh,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final result = await _searchHouses(queryState);
      if (requestVersion != _requestVersion) return;

      state = state.copyWith(
        page: result.page,
        hasMore: result.hasMore,
        houses: result.items,
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
      await saveSearchHistory(queryState.keyword);
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _messageFromError(error),
      );
    }
  }

  /// 下拉刷新，强制忽略缓存重新请求数据。
  Future<void> refresh() {
    return search(forceRefresh: true);
  }

  /// 加载下一页，自动去重后追加到列表末尾。
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }

    final nextState = state.copyWith(page: state.page + 1);
    final requestVersion = ++_requestVersion;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final result = await _searchHouses(nextState);
      if (requestVersion != _requestVersion) return;

      final knownIds = state.houses.map((house) => house.id).toSet();
      final newItems = result.items
          .where((house) => knownIds.add(house.id))
          .toList(growable: false);
      state = state.copyWith(
        page: result.page,
        hasMore: result.hasMore,
        houses: [...state.houses, ...newItems],
        isLoadingMore: false,
        clearError: true,
      );
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: _messageFromError(error),
      );
    }
  }

  /// 重置搜索状态，保留搜索历史和热门关键词后重新搜索。
  void reset() {
    _debounceTimer?.cancel();
    _requestVersion++;
    final history = state.searchHistory;
    final hotKeywords = state.hotKeywords;
    state = HouseSearchState(searchHistory: history, hotKeywords: hotKeywords);
    unawaited(search());
  }

  /// 点击关键词直接搜索，并保存到搜索历史。
  Future<void> selectKeyword(String keyword) async {
    _debounceTimer?.cancel();
    state = state.copyWith(keyword: keyword, clearError: true);
    await search();
  }

  /// 将非空关键词存入搜索历史。
  Future<void> saveSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    await ref.read(searchHistoryProvider.notifier).saveKeyword(keyword);
    state = state.copyWith(searchHistory: ref.read(searchHistoryProvider));
  }

  /// 从本地持久化存储读取搜索历史。
  Future<void> loadSearchHistory() async {
    state = state.copyWith(searchHistory: ref.read(searchHistoryProvider));
  }

  /// 清空所有搜索历史记录。
  Future<void> clearSearchHistory() async {
    await ref.read(searchHistoryProvider.notifier).clearHistory();
    state = state.copyWith(searchHistory: const []);
  }

  /// 加载热门搜索关键词列表。
  Future<void> loadHotKeywords() async {
    final keywords = ref.read(hotKeywordsProvider);
    state = state.copyWith(hotKeywords: keywords);
  }

  Future<PageResult<House>> _searchHouses(HouseSearchState queryState) {
    final service = ref.read(houseServiceProvider);
    return service.fetchHouses(_buildQuery(queryState));
  }

  Map<String, dynamic> _buildQuery(HouseSearchState value) {
    return <String, dynamic>{
      if (value.keyword.trim().isNotEmpty) 'keyword': value.keyword.trim(),
      if (value.category.isNotEmpty) 'category': value.category,
      if (value.region.isNotEmpty) 'region': value.region,
      if (value.minPrice > 0) 'minPrice': value.minPrice,
      if (value.maxPrice > 0) 'maxPrice': value.maxPrice,
      if (value.roomType.isNotEmpty) 'roomType': value.roomType,
      'sort': value.sort,
      'page': value.page,
      'pageSize': _pageSize,
    };
  }

  String _messageFromError(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return '房源加载失败，请稍后重试';
  }
}
