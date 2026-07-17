import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/storage_service.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/auth_controller.dart';

enum AppMode {
  tenant('tenant'),
  landlord('landlord');

  const AppMode(this.code);

  final String code;

  static AppMode fromCode(String? code) {
    return code == AppMode.landlord.code ? AppMode.landlord : AppMode.tenant;
  }
}

final appModeStorageProvider = Provider<LocalStorage?>((ref) {
  try {
    return StorageService.localStorage;
  } on Object {
    // 部分纯 Widget 测试不会执行应用启动阶段的 StorageService.initialize。
    return null;
  }
});

final appModeProvider = StateNotifierProvider<AppModeController, AppMode>((
  ref,
) {
  final controller = AppModeController(ref.watch(appModeStorageProvider));
  controller.syncUser(ref.read(authControllerProvider).user);
  ref.listen<AuthState>(authControllerProvider, (_, next) {
    controller.syncUser(next.user);
  });
  return controller;
});

class AppModeController extends StateNotifier<AppMode> {
  AppModeController(this._storage) : super(AppMode.tenant);

  final LocalStorage? _storage;
  String? _userId;
  bool _canUseLandlordMode = false;

  void syncUser(AuthUser? user) {
    _userId = user?.id;
    _canUseLandlordMode = user?.role.usesLandlordShell ?? false;
    if (user == null || !_canUseLandlordMode) {
      state = AppMode.tenant;
      return;
    }
    state = AppMode.fromCode(_storage?.getString(_storageKey(user.id)));
  }

  Future<void> setMode(AppMode mode) async {
    final userId = _userId;
    final nextMode = mode == AppMode.landlord && !_canUseLandlordMode
        ? AppMode.tenant
        : mode;
    state = nextMode;
    if (userId != null) {
      await _storage?.setString(_storageKey(userId), nextMode.code);
    }
  }

  static String _storageKey(String userId) {
    return '${StorageKeys.lastAppModePrefix}$userId';
  }
}
