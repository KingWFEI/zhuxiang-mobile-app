import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../models/profile_models.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient);
});

/// 当前所有租约 + 门锁信息
final currentHomeProvider =
    FutureProvider<({List<CurrentHome> homes, LockInfo? lock})?>((ref) async {
      final service = ref.watch(profileServiceProvider);
      final homes = await service.getCurrentHomes();
      LockInfo? lock;
      try {
        lock = await service.getLockInfo();
      } on Object {
        // 忽略单个接口错误
      }
      if (homes.isEmpty && lock == null) return null;
      return (homes: homes, lock: lock);
    });
