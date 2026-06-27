import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../staff/lock_initial/services/ttlock_ble_service.dart';
import '../../application/tenant_lock_unlock_controller.dart';
import '../repositories/tenant_lock_repository.dart';

final tenantLockRepositoryProvider = Provider<TenantLockRepositoryContract>((
  ref,
) {
  return TenantLockRepository(ref.watch(apiClientProvider));
});

final tenantTtlockBleServiceProvider = Provider<TtlockBleServiceContract>((
  ref,
) {
  return TtlockBleService();
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
      );
      scheduleMicrotask(controller.load);
      return controller;
    });
