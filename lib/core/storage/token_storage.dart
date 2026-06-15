import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime expiresAt;

  bool get isExpired {
    const refreshBefore = Duration(seconds: 30);
    return DateTime.now().add(refreshBefore).isAfter(expiresAt);
  }
}

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
      _storage.write(
        key: StorageKeys.accessTokenExpiresIn,
        value: expiresIn.toString(),
      ),
      _storage.write(
        key: StorageKeys.accessTokenExpiresAt,
        value: expiresAt.toIso8601String(),
      ),
    ]);
  }

  Future<StoredTokens?> readTokens() async {
    final values = await Future.wait([
      _storage.read(key: StorageKeys.accessToken),
      _storage.read(key: StorageKeys.refreshToken),
      _storage.read(key: StorageKeys.accessTokenExpiresIn),
      _storage.read(key: StorageKeys.accessTokenExpiresAt),
    ]);

    final accessToken = values[0];
    final refreshToken = values[1];
    final expiresIn = int.tryParse(values[2] ?? '');
    final expiresAt = DateTime.tryParse(values[3] ?? '');
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        expiresIn == null ||
        expiresAt == null) {
      return null;
    }

    return StoredTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      expiresAt: expiresAt,
    );
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> saveAccessToken(String accessToken) {
    return _storage.write(key: StorageKeys.accessToken, value: accessToken);
  }

  Future<void> saveUserJson(String userJson) {
    return _storage.write(key: StorageKeys.authUser, value: userJson);
  }

  Future<String?> readUserJson() {
    return _storage.read(key: StorageKeys.authUser);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.accessTokenExpiresIn),
      _storage.delete(key: StorageKeys.accessTokenExpiresAt),
      _storage.delete(key: StorageKeys.authUser),
    ]);
  }
}
