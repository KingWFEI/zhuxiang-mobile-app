import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/lock_record_service.dart';
import '../domain/entities/unlock_record.dart';

class LockRecordState {
  const LockRecordState({
    this.overview,
    this.selectedFilter = UnlockRecordFilter.all,
    this.isLoading = true,
    this.errorMessage,
  });

  final UnlockRecordOverview? overview;
  final UnlockRecordFilter selectedFilter;
  final bool isLoading;
  final String? errorMessage;

  List<UnlockRecord> get filteredRecords {
    final records = overview?.records ?? const <UnlockRecord>[];
    return switch (selectedFilter) {
      UnlockRecordFilter.all => records,
      UnlockRecordFilter.success =>
        records
            .where((record) => record.unlockResult == UnlockResult.success)
            .toList(),
      UnlockRecordFilter.failed =>
        records
            .where((record) => record.unlockResult == UnlockResult.failed)
            .toList(),
      UnlockRecordFilter.bluetooth =>
        records
            .where((record) => record.unlockMethod == UnlockMethod.bluetooth)
            .toList(),
      UnlockRecordFilter.remote =>
        records
            .where((record) => record.unlockMethod == UnlockMethod.remote)
            .toList(),
      UnlockRecordFilter.password =>
        records
            .where((record) => record.unlockMethod == UnlockMethod.password)
            .toList(),
    };
  }

  int get todayCount {
    final now = DateTime.now();
    return (overview?.records ?? const <UnlockRecord>[])
        .where(
          (record) =>
              record.unlockTime.year == now.year &&
              record.unlockTime.month == now.month &&
              record.unlockTime.day == now.day,
        )
        .length;
  }

  int get monthCount {
    final now = DateTime.now();
    return (overview?.records ?? const <UnlockRecord>[])
        .where(
          (record) =>
              record.unlockTime.year == now.year &&
              record.unlockTime.month == now.month,
        )
        .length;
  }

  int get abnormalCount => (overview?.records ?? const <UnlockRecord>[])
      .where((record) => !record.isSuccess)
      .length;

  LockRecordState copyWith({
    UnlockRecordOverview? overview,
    UnlockRecordFilter? selectedFilter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LockRecordState(
      overview: overview ?? this.overview,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LockRecordController extends StateNotifier<LockRecordState> {
  LockRecordController(this._service) : super(const LockRecordState());

  final LockRecordServiceContract _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final overview = await _service.fetchOverview();
      if (!mounted) return;
      state = LockRecordState(
        overview: overview,
        selectedFilter: state.selectedFilter,
        isLoading: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = LockRecordState(
        selectedFilter: state.selectedFilter,
        isLoading: false,
        errorMessage: '开门记录加载失败',
      );
    }
  }

  void selectFilter(UnlockRecordFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}
