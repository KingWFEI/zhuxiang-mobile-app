import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../application/lease_controller.dart';
import '../../domain/entities/deposit.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/lease_contract_document.dart';
import '../services/lease_service.dart';

final leaseServiceProvider = Provider<LeaseServiceContract>((ref) {
  return LeaseService(
    ref.watch(apiClientProvider),
    // 我的租约只展示后端真实数据，接口失败时交给页面展示错误 message。
    allowMockFallback: false,
  );
});

final leaseControllerProvider =
    StateNotifierProvider.autoDispose<LeaseController, LeaseState>((ref) {
      final controller = LeaseController(ref.watch(leaseServiceProvider));
      unawaited(Future<void>.microtask(controller.load));
      return controller;
    });

final leaseDetailProvider = FutureProvider.autoDispose.family<Lease, String>((
  ref,
  leaseId,
) {
  return ref.watch(leaseServiceProvider).getLeaseDetail(leaseId);
});

final leaseContractProvider = FutureProvider.autoDispose
    .family<LeaseContractDocument, String>((ref, leaseId) {
      return ref.watch(leaseServiceProvider).getLeaseContract(leaseId);
    });

final depositDetailProvider = FutureProvider.autoDispose
    .family<DepositInfo?, String>((ref, leaseId) {
      return ref.watch(leaseServiceProvider).getDeposit(leaseId);
    });
