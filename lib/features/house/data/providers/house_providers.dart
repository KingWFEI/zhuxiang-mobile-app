import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/house/data/models/house_detail.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/storage/storage_service.dart';
import '../../application/house_search_notifier.dart';
import '../house_cache.dart';
import '../house_repository.dart';
import '../services/house_service.dart';
import '../../domain/house_search_state.dart';

final houseServiceProvider = Provider<HouseService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HouseService(apiClient);
});

// 获取房源详情信息
final houseDetailProvider =
    FutureProvider.family<ApiResult<HouseDetail>, String>((ref, houseId) async {
      final service = ref.watch(houseServiceProvider);
      return service.getHouseDetail(houseId);
    });

final houseCacheProvider = Provider<HouseCache>((ref) {
  return HouseCache();
});

final houseRepositoryProvider = Provider<HouseRepository>((ref) {
  return HouseRepository(
    service: ref.watch(houseServiceProvider),
    localStorage: StorageService.localStorage,
  );
});

final houseSearchProvider =
    StateNotifierProvider<HouseSearchNotifier, HouseSearchState>((ref) {
      final notifier = HouseSearchNotifier(
        repository: ref.watch(houseRepositoryProvider),
        cache: ref.watch(houseCacheProvider),
      );
      unawaited(Future<void>.microtask(notifier.initialize));
      return notifier;
    });
