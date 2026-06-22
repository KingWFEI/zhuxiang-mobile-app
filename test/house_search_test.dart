import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/storage/local_storage.dart';
import 'package:zhuxiang_app/core/network/api_client_provider.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/application/house_search_notifier.dart';
import 'package:zhuxiang_app/features/house/data/house_cache.dart';
import 'package:zhuxiang_app/features/house/data/house_repository.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';
import 'package:zhuxiang_app/features/house/data/services/house_service.dart';
import 'package:zhuxiang_app/features/house/domain/entities/hot_community.dart';
import 'package:zhuxiang_app/features/house/domain/entities/house.dart';
import 'package:zhuxiang_app/features/house/domain/house_search_state.dart';
import 'package:zhuxiang_app/features/house/presentation/pages/find_house_page.dart';
import 'package:zhuxiang_app/features/house/presentation/pages/house_filter_page.dart';
import 'package:zhuxiang_app/features/house/presentation/pages/house_search_page.dart';
import 'package:zhuxiang_app/features/house/presentation/pages/house_search_result_page.dart';
import 'package:zhuxiang_app/features/house/data/providers/house_providers.dart';
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
      expect(history.take(2), ['地铁', '两居']);
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

  test('mock service returns six houses and supports rent sorting', () async {
    final service = HouseService(ApiClient());
    final result = await service.fetchHouses(const {
      'sort': 'price_asc',
      'page': 1,
      'pageSize': 20,
    });

    expect(result.items, hasLength(6));
    expect(result.items.first.title, '精致单间 · 配套齐全');
    expect(result.items.last.title, '智能门锁房 · 拎包入住');
  });

  test('house service provider injects the shared api client', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final apiClient = container.read(apiClientProvider);
    final service = container.read(houseServiceProvider);

    expect(service.apiClient, same(apiClient));
  });

  testWidgets('find home page renders provider state without network access', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeHouseRepository()..history = ['中央公园'];
    final notifier = HouseSearchNotifier(
      repository: repository,
      cache: HouseCache(),
    );
    await Future.wait([
      notifier.loadHotKeywords(),
      notifier.loadSearchHistory(),
    ]);
    await notifier.search();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: FindHomePage()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('住享'), findsAtLeastNWidgets(1));
    expect(find.text('重庆'), findsOneWidget);
    expect(find.textContaining('1286'), findsOneWidget);
    expect(find.text('测试房源 house-1'), findsOneWidget);
    expect(find.text('区域'), findsOneWidget);
    expect(find.text('排序'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find home page has no overflow on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = HouseSearchNotifier(
      repository: _FakeHouseRepository(),
      cache: HouseCache(),
    );
    await notifier.search();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: FindHomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('地图找房'), findsOneWidget);
    expect(find.text('测试房源 house-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search page only renders discovery content', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeHouseRepository()..history = ['中央公园'];
    final notifier = HouseSearchNotifier(
      repository: repository,
      cache: HouseCache(),
    );
    await Future.wait([
      notifier.loadHotKeywords(),
      notifier.loadSearchHistory(),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: HouseSearchPage()),
      ),
    );
    await tester.pump();

    expect(find.text('热门搜索'), findsOneWidget);
    expect(find.text('热门小区'), findsOneWidget);
    expect(find.text('搜索历史'), findsOneWidget);
    expect(find.text('搜索结果'), findsNothing);
    expect(find.byType(HouseSearchResultPage), findsNothing);
    final backIconLeft = tester
        .getTopLeft(find.byIcon(Icons.arrow_back_ios_new_rounded))
        .dx;
    final historyTitleLeft = tester.getTopLeft(find.text('搜索历史')).dx;
    expect(backIconLeft, moreOrLessEquals(historyTitleLeft, epsilon: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('search result page renders full house list', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = HouseSearchNotifier(
      repository: _FakeHouseRepository(),
      cache: HouseCache(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: HouseSearchResultPage(keyword: '测试')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试'), findsOneWidget);
    expect(find.text('测试房源 house-1'), findsOneWidget);
    expect(find.text('筛选'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full screen filter has no overflow on narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = HouseSearchNotifier(
      repository: _FakeHouseRepository(),
      cache: HouseCache(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: HouseFilterPage()),
      ),
    );
    await tester.pump();

    expect(find.text('筛选房源'), findsOneWidget);
    expect(find.text('查看房源（1286套）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('find search result and detail routes form a complete flow', (
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
    await notifier.search();

    final router = GoRouter(
      initialLocation: '/houses',
      routes: [
        GoRoute(
          name: 'search',
          path: '/houses',
          builder: (_, _) => const FindHomePage(),
          routes: [
            GoRoute(
              name: 'houseSearchResult',
              path: 'results',
              builder: (_, state) => HouseSearchResultPage(
                keyword: state.uri.queryParameters['keyword'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          name: 'houseSearch',
          path: '/house-search',
          builder: (_, _) => const HouseSearchPage(),
        ),
        GoRoute(
          name: 'houseDetail',
          path: '/detail/:houseId',
          builder: (_, state) =>
              Scaffold(body: Text('detail:${state.pathParameters['houseId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [houseSearchProvider.overrideWith((ref) => notifier)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('搜索小区、地铁、区域或房源'));
    await tester.pumpAndSettle();
    expect(find.byType(HouseSearchPage), findsOneWidget);

    await tester.enterText(find.byType(TextField), '测试');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byType(HouseSearchResultPage), findsOneWidget);

    await tester.tap(find.text('测试房源 house-1'));
    await tester.pumpAndSettle();
    expect(find.text('detail:house-1'), findsOneWidget);
  });
}

class _RecordingHouseService extends HouseService {
  _RecordingHouseService() : super(ApiClient());

  Map<String, dynamic>? lastQuery;

  @override
  List<HotCommunity> getHotCommunities() => const [];

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
  Future<ApiResult<HouseDetail>> getHouseDetail(String houseId) {
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
