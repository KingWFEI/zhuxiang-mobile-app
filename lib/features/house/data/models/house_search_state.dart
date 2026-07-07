import 'house.dart';

class HouseSearchState {
  const HouseSearchState({
    this.keyword = '',
    this.category = '',
    this.region = '',
    this.minPrice = 0,
    this.maxPrice = 0,
    this.roomType = '',
    this.sort = 'default',
    this.activeTags = const <String>{},
    this.decoration = '',
    this.orientation = '',
    this.page = 1,
    this.totalCount = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.houses = const [],
    this.searchHistory = const [],
    this.hotKeywords = const [],
    this.error,
  });

  final String keyword;
  final String category;
  final String region;
  final int minPrice;
  final int maxPrice;
  final String roomType;
  final String sort;
  final Set<String> activeTags;
  final String decoration;
  final String orientation;

  final int page;
  final int totalCount;
  final bool hasMore;

  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;

  final List<House> houses;
  final List<String> searchHistory;
  final List<String> hotKeywords;
  final String? error;

  bool get hasActiveFilters {
    return category.isNotEmpty ||
        region.isNotEmpty ||
        minPrice > 0 ||
        maxPrice > 0 ||
        roomType.isNotEmpty ||
        sort != 'default';
  }

  int get activeFilterCount {
    var count = 0;
    if (region.isNotEmpty) count++;
    if (minPrice > 0 || maxPrice > 0) count++;
    if (roomType.isNotEmpty) count++;
    if (sort != 'default') count++;
    return count;
  }

  HouseSearchState copyWith({
    String? keyword,
    String? category,
    String? region,
    int? minPrice,
    int? maxPrice,
    String? roomType,
    String? sort,
    Set<String>? activeTags,
    String? decoration,
    String? orientation,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    List<House>? houses,
    List<String>? searchHistory,
    List<String>? hotKeywords,
    String? error,
    bool clearError = false,
  }) {
    return HouseSearchState(
      keyword: keyword ?? this.keyword,
      category: category ?? this.category,
      region: region ?? this.region,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      roomType: roomType ?? this.roomType,
      sort: sort ?? this.sort,
      activeTags: activeTags ?? this.activeTags,
      decoration: decoration ?? this.decoration,
      orientation: orientation ?? this.orientation,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      houses: houses ?? this.houses,
      searchHistory: searchHistory ?? this.searchHistory,
      hotKeywords: hotKeywords ?? this.hotKeywords,
      error: clearError ? null : error ?? this.error,
    );
  }
}
