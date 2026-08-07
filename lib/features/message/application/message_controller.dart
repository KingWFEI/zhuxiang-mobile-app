import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/services/message_service.dart';
import '../domain/entities/app_message.dart';
import '../domain/entities/message_realtime_event.dart';

class MessageState {
  const MessageState({
    this.messages = const [],
    this.category,
    this.unreadCounts = const MessageUnreadCounts(),
    this.page = 1,
    this.total = 0,
    this.hasMore = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.errorMessage,
  });

  final List<AppMessage> messages;
  final MessageCategory? category;
  final MessageUnreadCounts unreadCounts;
  final int page;
  final int total;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isMutating;
  final String? errorMessage;

  MessageState copyWith({
    List<AppMessage>? messages,
    MessageCategory? category,
    bool clearCategory = false,
    MessageUnreadCounts? unreadCounts,
    int? page,
    int? total,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      category: clearCategory ? null : category ?? this.category,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MessageController extends StateNotifier<MessageState> {
  MessageController(this._service) : super(const MessageState());

  static const pageSize = 20;
  final MessageServiceContract _service;
  bool _isRefreshingUnread = false;
  Timer? _realtimeSyncDebounce;
  Timer? _realtimeRefreshDebounce;

  Future<void> loadInitial() async {
    if (state.isInitialLoading) return;
    state = state.copyWith(
      messages: const [],
      page: 1,
      hasMore: false,
      isInitialLoading: true,
      clearError: true,
    );

    final listFuture = _service.fetchMessages(
      category: state.category,
      page: 1,
      pageSize: pageSize,
    );
    final countsFuture = _service.fetchUnreadCounts();
    final listResult = await listFuture;
    final countsResult = await countsFuture;
    if (!mounted) return;

    final counts = countsResult is ApiSuccess<MessageUnreadCounts>
        ? countsResult.data
        : state.unreadCounts;
    if (listResult is ApiSuccess<MessagePageData>) {
      final data = listResult.data;
      state = state.copyWith(
        messages: data.items,
        unreadCounts: counts,
        page: data.page,
        total: data.total,
        hasMore: data.hasMore,
        isInitialLoading: false,
        clearError: true,
      );
    } else {
      final failure = listResult as ApiFailure<MessagePageData>;
      state = state.copyWith(
        unreadCounts: counts,
        isInitialLoading: false,
        errorMessage: _friendlyError(failure.message),
      );
    }
  }

  Future<void> selectCategory(MessageCategory? category) async {
    if (state.category == category) return;
    state = state.copyWith(category: category, clearCategory: category == null);
    await loadInitial();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    final listFuture = _service.fetchMessages(
      category: state.category,
      page: 1,
      pageSize: pageSize,
    );
    final countsFuture = _service.fetchUnreadCounts();
    final listResult = await listFuture;
    final countsResult = await countsFuture;
    if (!mounted) return;

    var next = state.copyWith(isRefreshing: false);
    if (countsResult is ApiSuccess<MessageUnreadCounts>) {
      next = next.copyWith(unreadCounts: countsResult.data);
    }
    if (listResult is ApiSuccess<MessagePageData>) {
      final data = listResult.data;
      next = next.copyWith(
        messages: data.items,
        page: data.page,
        total: data.total,
        hasMore: data.hasMore,
        clearError: true,
      );
    } else if (state.messages.isEmpty) {
      next = next.copyWith(
        errorMessage: _friendlyError(
          (listResult as ApiFailure<MessagePageData>).message,
        ),
      );
    }
    state = next;
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isInitialLoading ||
        state.isRefreshing) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    final result = await _service.fetchMessages(
      category: state.category,
      page: state.page + 1,
      pageSize: pageSize,
    );
    if (!mounted) return;
    if (result is ApiSuccess<MessagePageData>) {
      final data = result.data;
      final merged = [...state.messages, ...data.items];
      final seen = <String>{};
      state = state.copyWith(
        messages: [
          for (final item in merged)
            if (seen.add(item.id)) item,
        ],
        page: data.page,
        total: data.total,
        hasMore: data.hasMore,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> markAsRead(AppMessage message) async {
    if (message.isRead || message.id.isEmpty) return true;
    final result = await _service.markAsRead(message.id);
    if (!mounted) return false;
    if (result is! ApiSuccess<bool> || !result.data) return false;
    state = state.copyWith(
      messages: [
        for (final item in state.messages)
          if (item.id == message.id) item.copyWith(isRead: true) else item,
      ],
    );
    await refreshUnreadCounts();
    return true;
  }

  Future<bool> markAllAsRead() async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true);
    // 后端当前只支持全部消息已读，不支持按分类传 category。
    final result = await _service.markAllAsRead();
    if (!mounted) return false;
    if (result is! ApiSuccess<bool> || !result.data) {
      state = state.copyWith(isMutating: false);
      return false;
    }
    state = state.copyWith(
      messages: [
        for (final item in state.messages) item.copyWith(isRead: true),
      ],
      unreadCounts: const MessageUnreadCounts(),
      isMutating: false,
    );
    await refresh();
    return true;
  }

  Future<bool> deleteMessage(String id) async {
    if (id.isEmpty || state.isMutating) return false;
    final result = await _service.deleteMessage(id);
    return result is ApiSuccess<bool> && result.data;
  }

  Future<void> handleDeletedMessage(String id) async {
    if (!mounted) return;
    state = state.copyWith(
      messages: state.messages.where((item) => item.id != id).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
    await refresh();
  }

  Future<bool> clearReadMessages() async {
    if (state.isMutating) return false;
    state = state.copyWith(isMutating: true);
    final result = await _service.clearReadMessages();
    if (!mounted) return false;
    if (result is! ApiSuccess<bool> || !result.data) {
      state = state.copyWith(isMutating: false);
      return false;
    }
    state = state.copyWith(isMutating: false);
    await refresh();
    return true;
  }

  Future<void> refreshUnreadCounts() async {
    if (_isRefreshingUnread) return;
    _isRefreshingUnread = true;
    try {
      final result = await _service.fetchUnreadCounts();
      if (mounted && result is ApiSuccess<MessageUnreadCounts>) {
        state = state.copyWith(unreadCounts: result.data);
      }
    } finally {
      _isRefreshingUnread = false;
    }
  }

  Future<void> handleRealtimeConnected() async {
    if (!mounted) return;
    if (state.isInitialLoading || state.isRefreshing) return;
    if (state.messages.isEmpty) {
      await loadInitial();
    } else {
      await refresh();
    }
  }

  Future<void> handleRealtimeEvent(MessageRealtimeEvent event) async {
    if (!mounted) return;
    if (event.type == 'message.created' && event.message != null) {
      final message = event.message!;
      final alreadyExists = state.messages.any((item) => item.id == message.id);
      final categoryMatches =
          state.category == null || state.category == message.category;
      if (!alreadyExists && categoryMatches) {
        state = state.copyWith(
          messages: [message, ...state.messages],
          total: state.total + 1,
        );
      }
      _scheduleRealtimeSync();
      return;
    }

    if (event.type != 'messages.changed') {
      await handleRealtimeConnected();
      return;
    }

    switch (event.operation) {
      case 'read':
        state = state.copyWith(
          messages: [
            for (final item in state.messages)
              if (item.id == event.messageId)
                item.copyWith(isRead: true)
              else
                item,
          ],
        );
      case 'read_all':
        state = state.copyWith(
          messages: [
            for (final item in state.messages) item.copyWith(isRead: true),
          ],
          unreadCounts: const MessageUnreadCounts(),
        );
      case 'deleted':
        final remaining = state.messages
            .where((item) => item.id != event.messageId)
            .toList();
        state = state.copyWith(
          messages: remaining,
          total:
              (state.total -
                      (remaining.length == state.messages.length ? 0 : 1))
                  .clamp(0, state.total)
                  .toInt(),
        );
        _scheduleRealtimeRefresh();
        return;
      case 'clear_read':
        final remaining = state.messages.where((item) => !item.isRead).toList();
        state = state.copyWith(
          messages: remaining,
          total: (state.total - (state.messages.length - remaining.length))
              .clamp(0, state.total)
              .toInt(),
        );
        _scheduleRealtimeRefresh();
        return;
      default:
        await handleRealtimeConnected();
        return;
    }
    _scheduleRealtimeSync();
  }

  void _scheduleRealtimeSync() {
    _realtimeSyncDebounce?.cancel();
    _realtimeSyncDebounce = Timer(
      const Duration(milliseconds: 300),
      refreshUnreadCounts,
    );
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(
      const Duration(milliseconds: 300),
      refresh,
    );
  }

  @override
  void dispose() {
    _realtimeSyncDebounce?.cancel();
    _realtimeRefreshDebounce?.cancel();
    super.dispose();
  }

  String _friendlyError(String message) {
    if (message.trim().isEmpty || message == 'Unknown network error') {
      return '消息加载失败，请稍后重试';
    }
    return message;
  }
}
