import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhuxiang_app/core/storage/local_storage.dart';
import 'package:zhuxiang_app/features/house/application/house_search_notifier.dart';
import 'package:zhuxiang_app/features/house/data/house_cache.dart';
import 'package:zhuxiang_app/features/house/data/house_repository.dart';
import 'package:zhuxiang_app/features/house/data/house_service.dart';
import 'package:zhuxiang_app/features/house/domain/entities/house.dart';
import 'package:zhuxiang_app/features/house/domain/house_search_state.dart';
import 'package:zhuxiang_app/features/house/presentation/pages/find_home_page.dart';
import 'package:zhuxiang_app/features/house/presentation/providers/house_providers.dart';
import 'package:zhuxiang_app/shared/models/page_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'repository builds backend query and persists deduplicated history',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = _RecordingHouseService();
      final repository = HouseRepository(
        service: service,
        localStorage: LocalStorage(preferences),
      );

      await repository.search(
        const HouseSearchState(
          keyword: ' 地铁 ',
          category: 'long_rent',
          region: 'jiangbei',
          minPrice: 100000,
          maxPrice: 500000,
          roomType: '2室1厅1卫',
          sort: 'price_asc',
          page: 2,
        ),
      );

      expect(service.lastQuery, {
        'keyword': '地铁',
        'category': 'long_rent',
        'region': 'jiangbei',
        'minPrice': 100000,
        'maxPrice': 500000,
        'roomType': '2室1厅1卫',
        'sort': 'price_asc',
        'page': 2,
        'pageSize': 20,
      });

      await repository.saveSearchKeyword('地铁');
      await repository.saveSearchKeyword('两居');
      final history = await repository.saveSearchKeyword('地铁');
      expect(history, ['地铁', '两居']);
    },
  );

  test('keyword updates debounce into one request', () async {
    final repository = _FakeHouseRepository();
    final notifier = HouseSearchNotifier(
      repository: repository,
      cache: HouseCache(),
    );
    addTearDown(notifier.dispose);

    notifier
      ..updateKeyword('近')
      ..updateKeyword('近地')
      ..updateKeyword('近地铁');

    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(repository.searchCount, 1);
    expect(repository.queries.single.keyword, '近地铁');
  });

  test('same query uses cache and pagination appends unique houses', () async {
    final repository = _FakeHouseRepository();
    final notifier = HouseSearchNotifier(
      repository: repository,
      cache: HouseCache(),
    );
    addTearDown(notifier.dispose);

    await notifier.search();
    await notifier.search();

    expect(repository.searchCount, 1);
    expect(notifier.state.houses.map((house) => house.id), ['house-1']);
    expect(notifier.state.hasMore, isTrue);

    await notifier.loadMore();

    expect(repository.searchCount, 2);
    expect(notifier.state.houses.map((house) => house.id), [
      'house-1',
      'house-2',
    ]);
    expect(notifier.state.page, 2);
    expect(notifier.state.hasMore, isFalse);
  });

  testWidgets('find home page renders provider state without network access', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = HouseSearchNotifier(
      repository: _FakeHouseRepository(),
      cache: HouseCache(),
    );
    await notifier.loadHotKeywords();
    await notifier.search();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: FindHomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('住享找房'), findsOneWidget);
    expect(find.text('测试房源 house-1'), findsOneWidget);
    expect(find.text('热门搜索'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
  });
}

class _RecordingHouseService implements HouseService {
  Map<String, dynamic>? lastQuery;

  @override
  Future<PageResult<House>> fetchHouses(Map<String, dynamic> query) async {
    lastQuery = query;
    return const PageResult(
      items: [],
      page: 1,
      pageSize: 20,
      total: 0,
      hasMore: false,
    );
  }

  @override
  Future<House> getHouseDetail(String houseId) {
    throw UnimplementedError();
  }
}

class _FakeHouseRepository implements HouseRepository {
  int searchCount = 0;
  final List<HouseSearchState> queries = [];
  List<String> history = [];

  @override
  Future<PageResult<House>> search(HouseSearchState state) async {
    searchCount++;
    queries.add(state);
    if (state.page == 1) {
      return PageResult(
        items: [_house('house-1')],
        page: 1,
        pageSize: 20,
        total: 2,
        hasMore: true,
      );
    }
    return PageResult(
      items: [_house('house-1'), _house('house-2')],
      page: 2,
      pageSize: 20,
      total: 2,
      hasMore: false,
    );
  }

  @override
  Future<void> clearSearchHistory() async {
    history = [];
  }

  @override
  Future<List<String>> getHotKeywords() async => const ['近地铁'];

  @override
  Future<List<String>> getSearchHistory() async => history;

  @override
  Future<List<String>> saveSearchKeyword(String keyword) async {
    history = [keyword, ...history.where((item) => item != keyword)];
    return history;
  }
}

House _house(String id) {
  return House(
    id: id,
    title: '测试房源 $id',
    coverImage: '',
    location: '江北区',
    community: '测试小区',
    price: 268000,
    roomType: '1室1厅1卫',
    area: 42,
    floor: '12/28层',
    orientation: '朝南',
    tags: const ['近地铁'],
    facilities: const ['空调'],
    description: '测试',
    isSmartLockSupported: true,
    isFavorite: false,
    metro: '距地铁500m',
    decoration: '精装修',
    availableDate: '2026-07-01',
  );
}
