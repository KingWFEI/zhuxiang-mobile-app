import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../models/profile_models.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient);
});

/// 当前租约 + 门锁信息
final currentHomeProvider =
    FutureProvider<({CurrentHome? home, LockInfo? lock})?>((ref) async {
      final service = ref.watch(profileServiceProvider);
      final result = await service.getCurrentHomeWithLock();
      // 都为空时返回 null 表示无数据
      if (result.home == null && result.lock == null) return null;
      return result;
    });
