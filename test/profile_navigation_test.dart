import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/app/app.dart';
import 'package:zhuxiang_app/app/router/app_router.dart';
import 'package:zhuxiang_app/app/router/route_paths.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/core/storage/guest_mode_storage.dart';
import 'package:zhuxiang_app/core/storage/token_storage.dart';
import 'package:zhuxiang_app/features/auth/data/auth_repository.dart';
import 'package:zhuxiang_app/features/auth/domain/auth_usecases.dart';
import 'package:zhuxiang_app/features/auth/domain/entities/auth_user.dart';
import 'package:zhuxiang_app/features/auth/presentation/auth_controller.dart';
import 'package:zhuxiang_app/features/profile/data/providers/profile_providers.dart';
import 'package:zhuxiang_app/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:zhuxiang_app/features/message/data/providers/message_providers.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';

void main() {
  testWidgets('profile card opens profile edit page for tenant user', (
    tester,
  ) async {
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
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
        ],
        child: const ZhuxiangApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(_testUser.nickname), findsOneWidget);
    await tester.tap(find.text(_testUser.nickname));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ProfileEditPage), findsOneWidget);
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
          messageServiceProvider.overrideWithValue(_FakeMessageService()),
        ],
        child: const ZhuxiangApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump(const Duration(milliseconds: 400));
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
  isVerified: true,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  AuthUser _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<int> sendSmsCode({
    required String phone,
    required String scene,
  }) async {
    return 60;
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
