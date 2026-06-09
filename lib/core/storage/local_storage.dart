import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  const LocalStorage(this._preferences);

  final SharedPreferences _preferences;

  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  String? getString(String key) {
    return _preferences.getString(key);
  }

  Future<bool> remove(String key) {
    return _preferences.remove(key);
  }
}
