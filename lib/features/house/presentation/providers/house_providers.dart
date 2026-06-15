import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_service.dart';
import '../../application/house_search_notifier.dart';
import '../../data/house_cache.dart';
import '../../data/house_repository.dart';
import '../../data/house_service.dart';
import '../../domain/house_search_state.dart';

final houseServiceProvider = Provider<HouseService>((ref) {
  return HouseService();
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
