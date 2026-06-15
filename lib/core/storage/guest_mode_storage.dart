import '../constants/storage_keys.dart';
import 'local_storage.dart';

class GuestModeStorage {
  const GuestModeStorage(this._localStorage);

  final LocalStorage _localStorage;

  bool get isEnabled {
    return _localStorage.getBool(StorageKeys.guestModeEnabled) ?? false;
  }

  Future<void> enable() async {
    await _localStorage.setBool(StorageKeys.guestModeEnabled, true);
  }

  Future<void> clear() async {
    await _localStorage.remove(StorageKeys.guestModeEnabled);
  }
}
