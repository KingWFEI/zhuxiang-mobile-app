import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/storage/token_storage.dart';
import 'package:zhuxiang_app/features/auth/data/auth_models.dart';
import 'package:zhuxiang_app/features/auth/data/auth_repository_impl.dart';
import 'package:zhuxiang_app/features/auth/data/auth_service.dart';
import 'package:zhuxiang_app/features/auth/domain/entities/auth_user.dart';

void main() {
  const user = AuthUser(
    id: 'user-1',
    phone: '13800138000',
    nickname: '测试用户',
    avatarUrl: '',
    isVerified: false,
  );

  test('login persists tokens and user session', () async {
    final service = _FakeAuthService(
      authResult: const AuthResult(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresIn: 3600,
        user: user,
      ),
    );
    final storage = _FakeTokenStorage();
    final repository = AuthRepositoryImpl(service, storage);

    final result = await repository.loginWithPassword(
      phone: user.phone,
      password: '123456',
    );

    expect(result.id, user.id);
    expect(storage.tokens?.accessToken, 'access-1');
    expect(storage.tokens?.refreshToken, 'refresh-1');
    expect(storage.tokens?.expiresIn, 3600);
    expect(jsonDecode(storage.userJson!)['id'], user.id);
  });

  test('restore refreshes an expired access token', () async {
    final service = _FakeAuthService(
      authResult: const AuthResult(
        accessToken: 'unused',
        refreshToken: 'unused',
        expiresIn: 1,
        user: user,
      ),
      tokenResult: const TokenResult(
        accessToken: 'access-2',
        refreshToken: 'refresh-2',
        expiresIn: 7200,
      ),
    );
    final storage = _FakeTokenStorage()
      ..tokens = StoredTokens(
        accessToken: 'expired-access',
        refreshToken: 'refresh-1',
        expiresIn: 1,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      )
      ..userJson = jsonEncode(user.toJson());
    final repository = AuthRepositoryImpl(service, storage);

    final restoredUser = await repository.restoreSession();

    expect(restoredUser?.id, user.id);
    expect(service.refreshTokenReceived, 'refresh-1');
    expect(storage.tokens?.accessToken, 'access-2');
    expect(storage.tokens?.refreshToken, 'refresh-2');
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({required this.authResult, this.tokenResult});

  final AuthResult authResult;
  final TokenResult? tokenResult;
  String? refreshTokenReceived;

  @override
  Future<AuthResult> loginByCode({
    required String phone,
    required String code,
  }) async {
    return authResult;
  }

  @override
  Future<AuthResult> loginByPassword({
    required String phone,
    required String password,
  }) async {
    return authResult;
  }

  @override
  Future<bool> logout(String refreshToken) async {
    return true;
  }

  @override
  Future<TokenResult> refresh(String refreshToken) async {
    refreshTokenReceived = refreshToken;
    return tokenResult!;
  }

  @override
  Future<AuthResult> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  }) async {
    return authResult;
  }

  @override
  Future<SmsCodeResult> sendSmsCode({
    required String phone,
    required String scene,
  }) async {
    return const SmsCodeResult(expiresIn: 300);
  }
}

class _FakeTokenStorage implements TokenStorage {
  StoredTokens? tokens;
  String? userJson;

  @override
  Future<void> clear() async {
    tokens = null;
    userJson = null;
  }

  @override
  Future<String?> readAccessToken() async {
    return tokens?.accessToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {}

  @override
  Future<StoredTokens?> readTokens() async {
    return tokens;
  }

  @override
  Future<String?> readUserJson() async {
    return userJson;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    tokens = StoredTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  @override
  Future<void> saveUserJson(String userJson) async {
    this.userJson = userJson;
  }
}
