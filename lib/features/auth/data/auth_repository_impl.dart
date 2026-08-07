import 'dart:convert';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/entities/auth_user.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service, this._tokenStorage);

  final AuthService _service;
  final TokenStorage _tokenStorage;

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<SmsCodeResult> sendSmsCode({
    required String phone,
    required String scene,
  }) async {
    return _service.sendSmsCode(phone: phone, scene: scene);
  }

  @override
  Future<AuthUser> loginWithCode({
    required String phone,
    required String code,
  }) async {
    final result = await _service.loginByCode(phone: phone, code: code);
    await _saveSession(result);
    return result.user;
  }

  @override
  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _service.loginByPassword(
      phone: phone,
      password: password,
    );
    await _saveSession(result);
    return result.user;
  }

  @override
  Future<AuthUser> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  }) async {
    final result = await _service.register(
      phone: phone,
      code: code,
      password: password,
      nickname: nickname,
    );
    await _saveSession(result);
    return result.user;
  }

  @override
  Future<AuthUser?> restoreSession() async {
    try {
      final tokens = await _tokenStorage.readTokens();
      final userJson = await _tokenStorage.readUserJson();
      if (tokens == null || userJson == null || userJson.isEmpty) {
        await _clearSession();
        return null;
      }

      _currentUser = AuthUser.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      if (tokens.isExpired) {
        try {
          await _refresh(tokens.refreshToken);
        } on ApiException catch (e) {
          if (e.type == ApiExceptionType.unauthorized) {
            await _clearSession();
            _currentUser = null;
            return null;
          }
          // 网络错误/超时等 → 保留本地会话，允许离线使用
        }
      }
      return _currentUser;
    } on Object {
      await _clearSession();
      return null;
    }
  }

  @override
  Future<void> refreshSession() async {
    final tokens = await _tokenStorage.readTokens();
    if (tokens == null) {
      throw StateError('No refresh token is available');
    }
    await _refresh(tokens.refreshToken);
  }

  @override
  Future<void> updateUser(AuthUser user) async {
    _currentUser = user;
    await _tokenStorage.saveUserJson(jsonEncode(user.toJson()));
  }

  @override
  Future<void> logout() async {
    try {
      var tokens = await _tokenStorage.readTokens();
      if (tokens != null && tokens.isExpired) {
        try {
          await _refresh(tokens.refreshToken);
          tokens = await _tokenStorage.readTokens();
        } on Object {
          tokens = null;
        }
      }
      if (tokens != null) {
        await _service.logout(tokens.refreshToken);
      }
    } finally {
      await _clearSession();
    }
  }

  Future<void> _refresh(String refreshToken) async {
    final result = await _service.refresh(refreshToken);
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresIn: result.expiresIn,
    );
  }

  Future<void> _saveSession(AuthResult result) async {
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      expiresIn: result.expiresIn,
    );
    await _tokenStorage.saveUserJson(jsonEncode(result.user.toJson()));
    _currentUser = result.user;
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    await _tokenStorage.clear();
  }
}
