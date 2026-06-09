import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';
import 'secure_token_storage.dart';

class StorageService {
  const StorageService._();

  static late final LocalStorage localStorage;
  static final SecureTokenStorage secureTokenStorage = SecureTokenStorage();

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    localStorage = LocalStorage(preferences);
  }
}
