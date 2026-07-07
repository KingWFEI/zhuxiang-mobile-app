import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/cs_entities.dart';
import '../services/customer_service_api.dart';

// ── API Provider ──

final csApiProvider = Provider<CustomerServiceApi>((ref) {
  return CustomerServiceApi(ref.read(apiClientProvider));
});

// ── 会话列表（历史页用） ──

class SessionListState {
  const SessionListState({
    this.sessions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.page = 1,
  });

  final List<CsSession> sessions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int page;
}

class SessionListNotifier extends StateNotifier<SessionListState> {
  SessionListNotifier(this._api) : super(const SessionListState());
  final CustomerServiceApi _api;

  Future<void> loadInitial() async {
    state = const SessionListState(isLoading: true);
    final result = await _api.getSessions(page: 1);
    if (result case ApiSuccess<List<CsSession>>(:final data)) {
      state = SessionListState(
          sessions: data, hasMore: data.length >= 20, page: 1);
    } else if (result case ApiFailure(:final message)) {
      state = SessionListState(errorMessage: message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = SessionListState(
        sessions: state.sessions, isLoadingMore: true,
        hasMore: state.hasMore, page: state.page);
    final result = await _api.getSessions(page: nextPage);
    if (result case ApiSuccess<List<CsSession>>(:final data)) {
      state = SessionListState(
          sessions: [...state.sessions, ...data],
          hasMore: data.length >= 20, page: nextPage);
    } else {
      state = SessionListState(
          sessions: state.sessions, hasMore: state.hasMore, page: state.page);
    }
  }

  Future<void> refresh() async {
    final result = await _api.getSessions(page: 1);
    if (result case ApiSuccess<List<CsSession>>(:final data)) {
      state = SessionListState(sessions: data, hasMore: data.length >= 20, page: 1);
    }
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, SessionListState>(
  (ref) => SessionListNotifier(ref.read(csApiProvider)),
);
