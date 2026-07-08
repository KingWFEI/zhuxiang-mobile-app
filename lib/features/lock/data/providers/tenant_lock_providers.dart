import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../staff/lock_initial/services/ttlock_ble_service.dart';
import '../../application/auto_unlock_controller.dart';
import '../../application/tenant_lock_unlock_controller.dart';
import '../models/tenant_lock_unlock_data.dart';
import '../repositories/tenant_lock_repository.dart';

final tenantLockRepositoryProvider = Provider<TenantLockRepositoryContract>((
  ref,
) {
  return TenantLockRepository(ref.watch(apiClientProvider));
});

final autoUnlockRepositoryProvider = Provider<AutoUnlockRepositoryContract>((
  ref,
) {
  return TenantLockRepository(ref.watch(apiClientProvider));
});

final tenantTtlockBleServiceProvider = Provider<TtlockBleServiceContract>((
  ref,
) {
  return TtlockBleService();
});

final autoUnlockPreferenceStoreProvider = Provider<AutoUnlockPreferenceStore>((
  ref,
) {
  return LocalAutoUnlockPreferenceStore(StorageService.localStorage);
});

final autoUnlockEnvironmentProvider = Provider<AutoUnlockEnvironment>((ref) {
  return DeviceAutoUnlockEnvironment();
});

/// 按租约查询当前登录租客的门锁权限数据，不启动蓝牙扫描。
final tenantLockStatusProvider = FutureProvider.autoDispose
    .family<TenantLockUnlockData, String>((ref, leaseId) {
      return ref.watch(tenantLockRepositoryProvider).getUnlockData(leaseId);
    });

/// 按 leaseId 隔离租客门锁页面状态，页面退出后自动释放 lockData 和扫描资源。
final tenantLockUnlockProvider = StateNotifierProvider.autoDispose
    .family<TenantLockUnlockController, TenantLockUnlockState, String>((
      ref,
      leaseId,
    ) {
      final controller = TenantLockUnlockController(
        leaseId: leaseId,
        repository: ref.watch(tenantLockRepositoryProvider),
        ttlockBleService: ref.watch(tenantTtlockBleServiceProvider),
        unlockRecordRepository: ref.watch(autoUnlockRepositoryProvider),
        unlockEnvironment: ref.watch(autoUnlockEnvironmentProvider),
      );
      scheduleMicrotask(controller.load);
      return controller;
    });

/// 无感开锁与手动开锁同属当前页面生命周期，离开页面即释放 BLE 和 lockData。
final autoUnlockProvider = StateNotifierProvider.autoDispose
    .family<AutoUnlockController, AutoUnlockViewState, String>((ref, leaseId) {
      final controller = AutoUnlockController(
        leaseId: leaseId,
        repository: ref.watch(autoUnlockRepositoryProvider),
        bleService: ref.watch(tenantTtlockBleServiceProvider),
        preferenceStore: ref.watch(autoUnlockPreferenceStoreProvider),
        environment: ref.watch(autoUnlockEnvironmentProvider),
      );
      scheduleMicrotask(controller.initialize);
      return controller;
    });
