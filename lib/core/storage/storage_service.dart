import 'package:shared_preferences/shared_preferences.dart';

import 'guest_mode_storage.dart';
import 'local_storage.dart';
import 'secure_token_storage.dart';
import 'token_storage.dart';

class StorageService {
  const StorageService._();

  // 测试和热重启场景允许用新的 SharedPreferences 实例重新初始化。
  static late LocalStorage localStorage;
  static late GuestModeStorage guestModeStorage;
  static final TokenStorage tokenStorage = TokenStorage();
  static final SecureTokenStorage secureTokenStorage = SecureTokenStorage(
    tokenStorage: tokenStorage,
  );

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    localStorage = LocalStorage(preferences);
    guestModeStorage = GuestModeStorage(localStorage);
  }
}
