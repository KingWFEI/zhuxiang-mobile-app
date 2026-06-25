import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client_provider.dart';
import '../services/lock_api_service.dart';

final lockApiServiceProvider = Provider<LockApiService>((ref) {
  return LockApiService(ref.watch(apiClientProvider));
});

class LockInitState {
  const LockInitState({this.isSubmitting = false, this.errorMessage});
  final bool isSubmitting;
  final String? errorMessage;
  LockInitState copyWith({bool? isSubmitting, String? errorMessage}) {
    return LockInitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class LockInitNotifier extends Notifier<LockInitState> {
  @override
  LockInitState build() {
    return const LockInitState();
  }

  /// 步骤1：TTLock.initLock 成功后，保存本地初始化数据（不传 houseId/roomId）
  Future<LockLocalInitResponse?> saveLocalInit(
    LockLocalInitRequest request,
  ) async {
    if (state.isSubmitting) return null;

    state = const LockInitState(isSubmitting: true);

    try {
      final service = ref.read(lockApiServiceProvider);
      final response = await service.saveLocalInit(request);

      state = const LockInitState();
      return response;
    } catch (error) {
      state = LockInitState(errorMessage: error.toString());
      return null;
    }
  }

  /// 步骤2+3：绑定房源 → 同步开放平台（失败自动回滚绑定）
  Future<LockSyncPlatformResponse?> bindAndSync({
    required String smartLockId,
    required String houseId,
    String? roomId,
  }) async {
    if (state.isSubmitting) return null;

    state = const LockInitState(isSubmitting: true);

    try {
      final service = ref.read(lockApiServiceProvider);

      // 步骤2：绑定房源/房间
      await service.bindRoom(
        smartLockId,
        LockBindRoomRequest(houseId: houseId, roomId: roomId),
      );

      // 步骤3：同步开放平台
      try {
        final syncResponse = await service.syncPlatform(smartLockId);
        state = const LockInitState();
        return syncResponse;
      } catch (syncError) {
        // 同步失败，回滚绑定关系
        try {
          await service.deleteBindRoom(smartLockId);
        } catch (_) {}

        state = LockInitState(errorMessage: syncError.toString());
        return null;
      }
    } catch (error) {
      state = LockInitState(errorMessage: error.toString());
      return null;
    }
  }
}

final lockInitializeProvider =
    NotifierProvider<LockInitNotifier, LockInitState>(LockInitNotifier.new);
