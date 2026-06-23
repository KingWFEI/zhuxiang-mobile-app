import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/repair_service.dart';
import '../domain/entities/repair_order.dart';

class RepairState {
  const RepairState({
    this.overview,
    this.selectedFilter = RepairStatusFilter.all,
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.submitMessage,
  });

  final RepairOverview? overview;
  final RepairStatusFilter selectedFilter;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? submitMessage;

  List<RepairOrder> get filteredOrders {
    final orders = overview?.orders ?? const <RepairOrder>[];
    return orders.where(selectedFilter.matches).toList();
  }

  List<RepairOrder> get recentOrders =>
      (overview?.orders ?? const <RepairOrder>[]).take(3).toList();

  int countByFilter(RepairStatusFilter filter) {
    return (overview?.orders ?? const <RepairOrder>[])
        .where(filter.matches)
        .length;
  }

  RepairOrder? orderById(String id) {
    for (final order in overview?.orders ?? const <RepairOrder>[]) {
      if (order.id == id) return order;
    }
    return null;
  }

  RepairState copyWith({
    RepairOverview? overview,
    RepairStatusFilter? selectedFilter,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? submitMessage,
    bool clearError = false,
    bool clearSubmitMessage = false,
  }) {
    return RepairState(
      overview: overview ?? this.overview,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      submitMessage: clearSubmitMessage
          ? null
          : submitMessage ?? this.submitMessage,
    );
  }
}

class RepairController extends StateNotifier<RepairState> {
  RepairController(this._service) : super(const RepairState());

  final RepairServiceContract _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final overview = await _service.fetchOverview();
      if (!mounted) return;
      state = RepairState(
        overview: overview,
        selectedFilter: state.selectedFilter,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = RepairState(
        selectedFilter: state.selectedFilter,
        isLoading: false,
        errorMessage: '报修记录加载失败',
      );
    }
  }

  void selectFilter(RepairStatusFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<RepairOrder?> createRepair(CreateRepairRequest request) async {
    state = state.copyWith(isSubmitting: true, clearSubmitMessage: true);
    try {
      final order = await _service.createRepair(request);
      final currentOverview = state.overview;
      if (currentOverview != null) {
        state = state.copyWith(
          overview: RepairOverview(
            currentHouse: currentOverview.currentHouse,
            orders: [order, ...currentOverview.orders],
          ),
        );
      }
      if (!mounted) return order;
      state = state.copyWith(isSubmitting: false, submitMessage: '报修提交成功');
      return order;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(
        isSubmitting: false,
        submitMessage: '报修提交失败，请稍后重试',
      );
      return null;
    }
  }

  Future<bool> submitReview({
    required String repairId,
    required int rating,
    required String content,
  }) async {
    state = state.copyWith(isSubmitting: true, clearSubmitMessage: true);
    try {
      final updated = await _service.submitReview(
        repairId: repairId,
        rating: rating,
        content: content,
      );
      _replaceOrder(updated);
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false, submitMessage: '评价提交成功');
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false, submitMessage: '评价提交失败');
      return false;
    }
  }

  Future<bool> cancelRepair(String repairId) async {
    state = state.copyWith(isSubmitting: true, clearSubmitMessage: true);
    try {
      final updated = await _service.cancelRepair(repairId);
      _replaceOrder(updated);
      if (!mounted) return true;
      state = state.copyWith(isSubmitting: false, submitMessage: '工单已取消');
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false, submitMessage: '取消失败，请稍后重试');
      return false;
    }
  }

  void clearSubmitMessage() {
    state = state.copyWith(clearSubmitMessage: true);
  }

  void _replaceOrder(RepairOrder updated) {
    final currentOverview = state.overview;
    if (currentOverview == null) return;
    final orders = currentOverview.orders
        .map((order) => order.id == updated.id ? updated : order)
        .toList();
    state = state.copyWith(
      overview: RepairOverview(
        currentHouse: currentOverview.currentHouse,
        orders: orders,
      ),
    );
  }
}
