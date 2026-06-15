import 'token_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  Future<void> saveToken(String token) {
    return _tokenStorage.saveAccessToken(token);
  }

  Future<String?> getToken() {
    return _tokenStorage.readAccessToken();
  }

  Future<void> clearToken() {
    return _tokenStorage.clear();
  }
}
