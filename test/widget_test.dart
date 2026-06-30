import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/app.dart';
import 'package:zhuxiang_app/app/router/app_router.dart';
import 'package:zhuxiang_app/app/router/route_paths.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/core/storage/guest_mode_storage.dart';
import 'package:zhuxiang_app/core/storage/token_storage.dart';
import 'package:zhuxiang_app/features/auth/presentation/auth_controller.dart';
import 'package:zhuxiang_app/features/auth/presentation/pages/login_page.dart';
import 'package:zhuxiang_app/features/auth/presentation/pages/register_page.dart';
import 'package:zhuxiang_app/features/home/data/models/home_data.dart';
import 'package:zhuxiang_app/features/home/data/providers/home_providers.dart';
import 'package:zhuxiang_app/features/home/presentation/pages/home_page.dart';
import 'package:zhuxiang_app/features/message/data/providers/message_providers.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';

void main() {
  testWidgets('Zhuxiang app renders loading page', (tester) async {
    AppRouter.router.go(RoutePaths.splash);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
          guestModeStorageProvider.overrideWithValue(_FakeGuestModeStorage()),
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
          homeDataProvider.overrideWith(
            (ref) async => const ApiSuccess(_testHomeData),
          ),
        ],
        child: const ZhuxiangApp(),
      ),
    );
    await tester.pump();

    expect(find.text('住享'), findsOneWidget);
    expect(find.text('让每一次归家，都心中有数'), findsOneWidget);
    expect(find.bySemanticsLabel('住享社区建筑背景'), findsOneWidget);
    expect(find.bySemanticsLabel('正在加载'), findsOneWidget);
  });

  testWidgets('first launch without login enters login page', (tester) async {
    AppRouter.router.go(RoutePaths.splash);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
          guestModeStorageProvider.overrideWithValue(_FakeGuestModeStorage()),
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
          homeDataProvider.overrideWith(
            (ref) async => const ApiSuccess(_testHomeData),
          ),
        ],
        child: const ZhuxiangApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.text('欢迎登录'), findsOneWidget);
    expect(find.text('游客浏览'), findsOneWidget);
  });

  testWidgets('guest choice persists and opens main page on next launch', (
    tester,
  ) async {
    AppRouter.router.go(RoutePaths.splash);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final guestStorage = _FakeGuestModeStorage(enabled: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
          guestModeStorageProvider.overrideWithValue(guestStorage),
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
          homeDataProvider.overrideWith(
            (ref) async => const ApiSuccess(_testHomeData),
          ),
        ],
        child: const ZhuxiangApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.text('找房'), findsWidgets);
    expect(find.text('消息'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('guest browse button saves choice and enters main page', (
    tester,
  ) async {
    AppRouter.router.go(RoutePaths.splash);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final guestStorage = _FakeGuestModeStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
          guestModeStorageProvider.overrideWithValue(guestStorage),
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
          homeDataProvider.overrideWith(
            (ref) async => const ApiSuccess(_testHomeData),
          ),
        ],
        child: const ZhuxiangApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    await tester.tap(find.text('游客浏览'));
    await tester.pump();
    await tester.pump();

    expect(guestStorage.isEnabled, isTrue);
    expect(find.text('找房'), findsWidgets);
  });

  testWidgets('home page switches house categories without lock content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDataProvider.overrideWith(
            (ref) async => const ApiSuccess(_testHomeData),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('推荐'), findsWidgets);
    expect(find.text('短租'), findsOneWidget);
    expect(find.text('民宿'), findsOneWidget);
    expect(find.text('长租'), findsOneWidget);
    expect(find.text('我的租约'), findsOneWidget);
    expect(find.text('开门记录'), findsOneWidget);
    expect(find.text('报修服务'), findsOneWidget);
    expect(find.text('在线客服'), findsOneWidget);
    expect(find.text('我的家'), findsNothing);
    expect(find.text('蓝牙开锁'), findsNothing);
    expect(find.text('远程开锁'), findsNothing);
    expect(find.byType(SliverPersistentHeader), findsOneWidget);
    expect(find.byType(SliverMasonryGrid), findsWidgets);
    expect(find.text('品牌推荐'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('开门记录'));
    await tester.pump();

    expect(find.text('开门记录功能开发中'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('推荐').hitTestable(), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('home-tab-homestay')));
    await tester.pumpAndSettle();
    expect(find.text('城市民宿'), findsOneWidget);
    expect(find.text('精选专题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login page validates empty phone', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    final loginButton = find.widgetWithText(ElevatedButton, '登录');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('请输入手机号'), findsOneWidget);
  });

  testWidgets('login page switches between code and password modes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(_textFieldWithHint('验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('密码登录'), findsOneWidget);

    await tester.tap(find.text('密码登录'));
    await tester.pump();

    expect(_textFieldWithHint('密码'), findsOneWidget);
    expect(find.text('获取验证码'), findsNothing);
    expect(find.text('验证码登录'), findsOneWidget);

    final passwordField = tester.widget<TextField>(_textFieldWithHint('密码'));
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.text('验证码登录'));
    await tester.pump();

    expect(_textFieldWithHint('验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
  });

  testWidgets('invalid value is rejected in verification code mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    await tester.enterText(_textFieldWithHint('手机号'), '13800138000');
    await tester.enterText(_textFieldWithHint('验证码'), '12345');
    await tester.tap(find.byIcon(Icons.radio_button_unchecked_outlined));
    await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
    await tester.pump();

    expect(find.text('请输入6位验证码'), findsOneWidget);
  });

  testWidgets('register page validates empty phone', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterPage())),
    );

    final registerButton = find.widgetWithText(ElevatedButton, '注册');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.text('请输入手机号'), findsOneWidget);
  });
}

Finder _textFieldWithHint(String hintText) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hintText,
  );
}

const _testHomeData = HomeData(
  header: HomeHeaderData(
    cityName: '测试城市',
    greeting: '欢迎',
    subtitle: '',
    searchPlaceholder: '搜索房源',
    backgroundImageUrl: '',
  ),
  unreadMessageCount: 0,
  serviceEntries: [
    ServiceEntry(
      key: 'lease',
      title: '我的租约',
      iconKey: 'lease',
      targetType: 'route',
      targetValue: 'lease',
      requiresLogin: true,
      enabled: true,
    ),
    ServiceEntry(
      key: 'unlock',
      title: '开门记录',
      iconKey: 'lock',
      targetType: 'route',
      targetValue: 'unlock_records',
      requiresLogin: true,
      enabled: true,
    ),
    ServiceEntry(
      key: 'repair',
      title: '报修服务',
      iconKey: 'repair',
      targetType: 'route',
      targetValue: 'repairs',
      requiresLogin: true,
      enabled: true,
    ),
    ServiceEntry(
      key: 'service',
      title: '在线客服',
      iconKey: 'service',
      targetType: 'route',
      targetValue: 'customer_service',
      requiresLogin: false,
      enabled: true,
    ),
  ],
  tabs: [
    HomeTab(key: 'recommended', title: '推荐', sort: 1, enabled: true),
    HomeTab(key: 'short_rent', title: '短租', sort: 2, enabled: true),
    HomeTab(key: 'homestay', title: '民宿', sort: 3, enabled: true),
    HomeTab(key: 'long_rent', title: '长租', sort: 4, enabled: true),
  ],
  houseGroups: {
    'recommended': HomeHouseGroup(
      items: [
        HomeFeedItem(type: 'house', house: _testHouse),
        HomeFeedItem(
          type: 'advertisement',
          advertisement: HomeAdItem(
            id: 'ad-1',
            title: '品牌推荐',
            description: '品质房源',
            imageUrl: '',
            targetType: 'route',
            targetValue: '',
          ),
        ),
      ],
      page: 1,
      pageSize: 10,
      hasMore: false,
    ),
    'short_rent': HomeHouseGroup(
      items: [HomeFeedItem(type: 'house', house: _testHouse)],
      page: 1,
      pageSize: 10,
      hasMore: false,
    ),
    'homestay': HomeHouseGroup(
      items: [
        HomeFeedItem(
          type: 'house',
          house: HomeHouseItem(
            id: 'homestay-1',
            title: '城市民宿',
            coverImage: '',
            location: '渝中区',
            community: '江景雅苑',
            price: 38800,
            roomType: '1室1厅1卫',
            area: 50,
            floor: '18/30层',
            orientation: '朝东',
            tags: ['江景'],
            facilities: ['空调'],
            description: '城市民宿',
            isSmartLockSupported: true,
            isFavorite: false,
            metro: '距地铁600m',
            decoration: '品质装修',
            availableDate: '2026-06-15',
          ),
        ),
        HomeFeedItem(
          type: 'advertisement',
          advertisement: HomeAdItem(
            id: 'ad-2',
            title: '精选专题',
            description: '热门民宿',
            imageUrl: '',
            targetType: 'route',
            targetValue: '',
          ),
        ),
      ],
      page: 1,
      pageSize: 10,
      hasMore: false,
    ),
    'long_rent': HomeHouseGroup(
      items: [HomeFeedItem(type: 'house', house: _testHouse)],
      page: 1,
      pageSize: 10,
      hasMore: false,
    ),
  },
);

const _testHouse = HomeHouseItem(
  id: 'house-1',
  title: '温馨一居',
  coverImage: '',
  location: '渝北区',
  community: '幸福小区',
  price: 268000,
  roomType: '1室1厅1卫',
  area: 42,
  floor: '12/28层',
  orientation: '朝南',
  tags: ['近地铁'],
  facilities: ['空调'],
  description: '测试房源',
  isSmartLockSupported: true,
  isFavorite: false,
  metro: '距地铁500m',
  decoration: '精装修',
  availableDate: '2026-07-01',
);

class _EmptyTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> saveAccessToken(String accessToken) async {}

  @override
  Future<StoredTokens?> readTokens() async => null;

  @override
  Future<String?> readUserJson() async => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {}

  @override
  Future<void> saveUserJson(String userJson) async {}
}

class _FakeGuestModeStorage implements GuestModeStorage {
  _FakeGuestModeStorage({bool enabled = false}) : _enabled = enabled;

  bool _enabled;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> enable() async {
    _enabled = true;
  }

  @override
  Future<void> clear() async {
    _enabled = false;
  }
}

class _FakeMessageService implements MessageServiceContract {
  @override
  Future<ApiResult<MessagePageData>> fetchMessages({
    MessageCategory? category,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    return ApiSuccess(
      MessagePageData(
        items: const [],
        page: page,
        pageSize: pageSize,
        total: 0,
        hasMore: false,
      ),
    );
  }

  @override
  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts() async {
    return const ApiSuccess(MessageUnreadCounts());
  }

  @override
  Future<ApiResult<bool>> markAsRead(String id) async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> markAllAsRead() async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> deleteMessage(String id) async =>
      const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> clearReadMessages() async => const ApiSuccess(true);
}
