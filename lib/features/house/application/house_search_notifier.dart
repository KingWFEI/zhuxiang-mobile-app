import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/house_cache.dart';
import '../data/house_repository.dart';
import '../domain/house_search_state.dart';

class HouseSearchNotifier extends StateNotifier<HouseSearchState> {
  HouseSearchNotifier({
    required HouseRepository repository,
    required HouseCache cache,
  }) : _repository = repository,
       _cache = cache,
       super(const HouseSearchState());

  final HouseRepository _repository;
  final HouseCache _cache;

  Timer? _debounceTimer;
  int _requestVersion = 0;
  String? _activeRequestKey;

  Future<void> initialize() async {
    await Future.wait([loadSearchHistory(), loadHotKeywords()]);
    if (!mounted) return;
    await search();
  }

  void updateKeyword(String keyword) {
    _requestVersion++;
    _activeRequestKey = null;
    state = state.copyWith(keyword: keyword, clearError: true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), search);
  }

  void updateCategory(String category) {
    if (category == state.category) return;
    _debounceTimer?.cancel();
    state = state.copyWith(category: category, clearError: true);
    unawaited(search());
  }

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

  Future<void> search({bool forceRefresh = false}) async {
    final queryState = state.copyWith(page: 1);
    final requestKey = _requestKey(queryState);
    if (!forceRefresh && state.isLoading && _activeRequestKey == requestKey) {
      return;
    }

    final requestVersion = ++_requestVersion;
    _activeRequestKey = requestKey;

    if (!forceRefresh) {
      final cached = _cache.get(queryState);
      if (cached != null) {
        state = state.copyWith(
          page: cached.page,
          hasMore: cached.hasMore,
          houses: cached.items,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        );
        _activeRequestKey = null;
        await saveSearchHistory(queryState.keyword);
        return;
      }
    }

    state = state.copyWith(
      page: 1,
      isLoading: !forceRefresh,
      isRefreshing: forceRefresh,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final result = await _repository.search(queryState);
      if (!mounted || requestVersion != _requestVersion) return;

      _cache.set(queryState, result);
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
      if (!mounted || requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _messageFromError(error),
      );
    } finally {
      if (requestVersion == _requestVersion) {
        _activeRequestKey = null;
      }
    }
  }

  Future<void> refresh() {
    return search(forceRefresh: true);
  }

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
      final cached = _cache.get(nextState);
      final result = cached ?? await _repository.search(nextState);
      if (!mounted || requestVersion != _requestVersion) return;

      if (cached == null) {
        _cache.set(nextState, result);
      }
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
      if (!mounted || requestVersion != _requestVersion) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: _messageFromError(error),
      );
    }
  }

  void reset() {
    _debounceTimer?.cancel();
    _requestVersion++;
    final history = state.searchHistory;
    final hotKeywords = state.hotKeywords;
    state = HouseSearchState(searchHistory: history, hotKeywords: hotKeywords);
    unawaited(search());
  }

  Future<void> selectKeyword(String keyword) async {
    _debounceTimer?.cancel();
    state = state.copyWith(keyword: keyword, clearError: true);
    await search();
  }

  Future<void> saveSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final history = await _repository.saveSearchKeyword(keyword);
    if (!mounted) return;
    state = state.copyWith(searchHistory: history);
  }

  Future<void> loadSearchHistory() async {
    final history = await _repository.getSearchHistory();
    if (!mounted) return;
    state = state.copyWith(searchHistory: history);
  }

  Future<void> clearSearchHistory() async {
    await _repository.clearSearchHistory();
    if (!mounted) return;
    state = state.copyWith(searchHistory: const []);
  }

  Future<void> loadHotKeywords() async {
    final keywords = await _repository.getHotKeywords();
    if (!mounted) return;
    state = state.copyWith(hotKeywords: keywords);
  }

  String _requestKey(HouseSearchState value) {
    return [
      value.keyword.trim().toLowerCase(),
      value.category,
      value.region,
      value.minPrice,
      value.maxPrice,
      value.roomType,
      value.sort,
      value.page,
    ].join('|');
  }

  String _messageFromError(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return '房源加载失败，请稍后重试';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
