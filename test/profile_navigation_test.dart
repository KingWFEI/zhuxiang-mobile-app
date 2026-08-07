import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhuxiang_app/app/app.dart';
import 'package:zhuxiang_app/app/router/app_router.dart';
import 'package:zhuxiang_app/app/router/route_paths.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/core/storage/guest_mode_storage.dart';
import 'package:zhuxiang_app/core/storage/storage_service.dart';
import 'package:zhuxiang_app/core/storage/token_storage.dart';
import 'package:zhuxiang_app/features/auth/data/auth_repository.dart';
import 'package:zhuxiang_app/features/auth/data/auth_models.dart';
import 'package:zhuxiang_app/features/auth/domain/auth_usecases.dart';
import 'package:zhuxiang_app/features/auth/domain/entities/auth_user.dart';
import 'package:zhuxiang_app/features/auth/presentation/auth_controller.dart';
import 'package:zhuxiang_app/features/profile/data/models/profile_models.dart';
import 'package:zhuxiang_app/features/profile/data/providers/profile_providers.dart';
import 'package:zhuxiang_app/features/profile/presentation/pages/rented_home_detail_page.dart';
import 'package:zhuxiang_app/features/profile/presentation/pages/settings_page.dart';
import 'package:zhuxiang_app/features/message/data/providers/message_providers.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
  });

  test('profile models parse overview and rented-home fields', () {
    final overview = ProfileOverview.fromJson({
      'favoriteCount': 12,
      'appointmentCount': 3,
      'isVerified': true,
    });
    final home = CurrentHome.fromJson({
      'houseId': 'house-1',
      'title': '星河公寓 1203',
      'community': '星河公寓',
      'building': '3',
      'unit': '2',
      'room': '1203',
      'leaseId': 'lease-1',
      'leaseStatus': 'active',
      'lockId': 'lock-1',
      'lockStatus': 'BOUND',
      'monthlyRent': 368000,
      'leaseStartDate': '2026-03-01',
      'leaseEndDate': '2027-02-28',
    });

    expect(overview.favoriteCount, 12);
    expect(overview.appointmentCount, 3);
    expect(overview.isVerified, isTrue);
    expect(home.monthlyRent, 368000);
    expect(home.hasSmartLock, isTrue);
    expect(home.leaseEndDate, DateTime(2027, 2, 28));
  });

  testWidgets('profile page keeps tenant services and identity navigation', (
    tester,
  ) async {
    AppRouter.router.go(RoutePaths.splash);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              AuthUseCases(_FakeAuthRepository(_testUser)),
              _FakeGuestModeStorage(),
            ),
          ),
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
          guestModeStorageProvider.overrideWithValue(_FakeGuestModeStorage()),
          currentHomeProvider.overrideWith(
            (ref) async => (homes: [_testHome, _testSecondHome], lock: null),
          ),
          profileOverviewProvider.overrideWith(
            (ref) async => const ProfileOverview(
              favoriteCount: 12,
              appointmentCount: 3,
              isVerified: true,
            ),
          ),
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
        ],
        child: const ZhuxiangApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.text(_testUser.nickname), findsOneWidget);
    expect(find.text('正在租住'), findsOneWidget);
    expect(find.text('常用服务'), findsOneWidget);
    expect(find.text('更多功能'), findsOneWidget);
    expect(find.text('我的租约'), findsOneWidget);
    expect(find.text('我的预约'), findsOneWidget);
    expect(find.text('门锁管理'), findsOneWidget);
    expect(find.text('星河公寓 · 3栋2单元1203'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('预约'), findsOneWidget);
    expect(find.text('已认证'), findsOneWidget);
    expect(
      find.byKey(const Key('current-home-unlock-lease-1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('current-home-unlock-lease-2')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('profile-current-home-carousel')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('云栖社区 · 5栋1单元602'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('profile-current-home-carousel')),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('星河公寓 · 3栋2单元1203'));
    await tester.pumpAndSettle();
    expect(find.byType(RentedHomeDetailPage), findsOneWidget);
    expect(find.text('租约信息'), findsOneWidget);
    expect(find.text('智能门锁'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_testUser.nickname));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('logout from settings redirects to login page', (tester) async {
    AppRouter.router.go(RoutePaths.splash);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              AuthUseCases(_FakeAuthRepository(_testUser)),
              _FakeGuestModeStorage(),
            ),
          ),
          tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
          guestModeStorageProvider.overrideWithValue(_FakeGuestModeStorage()),
          currentHomeProvider.overrideWith((ref) async => null),
          profileOverviewProvider.overrideWith(
            (ref) async => const ProfileOverview(
              favoriteCount: 0,
              appointmentCount: 0,
              isVerified: true,
            ),
          ),
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
        ],
        child: const ZhuxiangApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('我的').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('正在租住'), findsNothing);
    await tester.ensureVisible(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '退出'));
    await tester.pumpAndSettle();

    expect(find.text('欢迎登录'), findsOneWidget);
  });
}

const _testUser = AuthUser(
  id: 'user-1',
  phone: '13800138000',
  nickname: 'Test User',
  avatarUrl: '',
  isVerified: false,
);

final _testHome = CurrentHome(
  houseId: 'house-1',
  community: '星河公寓',
  building: '3',
  unit: '2',
  room: '1203',
  leaseId: 'lease-1',
  leaseStatus: 'ACTIVE',
  lockId: 'lock-1',
  lockStatus: 'BOUND',
  address: '杭州市余杭区文一西路',
  roomType: '三室两厅一卫',
  area: 89,
  floor: '12/28层',
  orientation: '南北通透',
  monthlyRent: 368000,
  deposit: 368000,
  paymentMethod: '押一付三',
  leaseStartDate: DateTime(2026, 3, 1),
  leaseEndDate: DateTime(2027, 2, 28),
  sourceType: 'PLATFORM',
);

const _testSecondHome = CurrentHome(
  houseId: 'house-2',
  community: '云栖社区',
  building: '5',
  unit: '1',
  room: '602',
  leaseId: 'lease-2',
  leaseStatus: 'ACTIVE',
  lockStatus: 'UNBOUND',
  address: '杭州市西湖区文三路',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  AuthUser _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<SmsCodeResult> sendSmsCode({
    required String phone,
    required String scene,
  }) async {
    return const SmsCodeResult(expiresIn: 300, retryAfter: 60);
  }

  @override
  Future<AuthUser> loginWithCode({
    required String phone,
    required String code,
  }) async {
    return _user;
  }

  @override
  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    return _user;
  }

  @override
  Future<AuthUser> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  }) async {
    return _user;
  }

  @override
  Future<AuthUser?> restoreSession() async {
    return _user;
  }

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> updateUser(AuthUser user) async {
    _user = user;
  }

  @override
  Future<void> logout() async {}
}

class _EmptyTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<StoredTokens?> readTokens() async => null;

  @override
  Future<String?> readUserJson() async => null;

  @override
  Future<void> saveAccessToken(String accessToken) async {}

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
  bool _enabled = false;

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
  }) async => ApiSuccess(
    MessagePageData(
      items: const [],
      page: page,
      pageSize: pageSize,
      total: 0,
      hasMore: false,
    ),
  );

  @override
  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts() async =>
      const ApiSuccess(MessageUnreadCounts());

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
