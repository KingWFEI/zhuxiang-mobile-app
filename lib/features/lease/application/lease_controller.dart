import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../data/services/lease_service.dart';
import '../domain/entities/lease.dart';

class LeaseState {
  const LeaseState({
    this.leases = const [],
    this.isLoading = true,
    this.isOperating = false,
    this.errorMessage,
    this.actionMessage,
  });

  final List<Lease> leases;
  final bool isLoading;
  final bool isOperating;
  final String? errorMessage;
  final String? actionMessage;

  List<Lease> get currentLeases =>
      leases.where((lease) => lease.isCurrent).toList();
  List<Lease> get historyLeases =>
      leases.where((lease) => !lease.isCurrent).toList();

  LeaseState copyWith({
    List<Lease>? leases,
    bool? isLoading,
    bool? isOperating,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return LeaseState(
      leases: leases ?? this.leases,
      isLoading: isLoading ?? this.isLoading,
      isOperating: isOperating ?? this.isOperating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
    );
  }
}

class LeaseController extends StateNotifier<LeaseState> {
  LeaseController(this._service) : super(const LeaseState());

  final LeaseServiceContract _service;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearActionMessage: true,
    );
    try {
      final leases = await _service.getMyLeases();
      if (!mounted) return;
      state = LeaseState(leases: leases, isLoading: false);
    } catch (error) {
      if (!mounted) return;
      state = LeaseState(
        isLoading: false,
        errorMessage: _message(error, '租约加载失败，请稍后重试'),
      );
    }
  }

  Future<bool> renew(String leaseId) {
    return _operate(() => _service.renew(leaseId), successMessage: '续租申请已提交');
  }

  Future<bool> _operate(
    Future<void> Function() operation, {
    required String successMessage,
  }) async {
    state = state.copyWith(
      isOperating: true,
      clearError: true,
      clearActionMessage: true,
    );
    try {
      await operation();
      final leases = await _service.getMyLeases();
      if (!mounted) return false;
      state = LeaseState(
        leases: leases,
        isLoading: false,
        actionMessage: successMessage,
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        isOperating: false,
        errorMessage: _message(error, '操作失败，请稍后重试'),
      );
      return false;
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearActionMessage: true);
  }

  String _message(Object error, String fallback) {
    if (error is ApiException) {
      return error.message.isNotEmpty ? error.message : fallback;
    }
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? fallback : message;
  }
}
