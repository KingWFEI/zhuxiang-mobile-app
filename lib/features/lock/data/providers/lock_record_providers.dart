import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../application/lock_record_controller.dart';
import '../services/lock_record_service.dart';

final lockRecordServiceProvider = Provider<LockRecordServiceContract>((ref) {
  return LockRecordService(ref.watch(apiClientProvider));
});

final lockRecordControllerProvider =
    StateNotifierProvider.autoDispose<LockRecordController, LockRecordState>((
      ref,
    ) {
      final controller = LockRecordController(
        ref.watch(lockRecordServiceProvider),
      );
      unawaited(Future<void>.microtask(controller.load));
      return controller;
    });
