import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/auth/domain/entities/auth_user.dart';
import 'package:zhuxiang_app/features/auth/presentation/auth_controller.dart';
import 'package:zhuxiang_app/features/message/data/providers/message_providers.dart';
import 'package:zhuxiang_app/features/message/data/realtime/message_sse_client.dart';
import 'package:zhuxiang_app/features/message/data/realtime/sse_event.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';
import 'package:zhuxiang_app/features/message/domain/entities/message_realtime_event.dart';

void main() {
  testWidgets('switching account disposes previous message cache', (
    tester,
  ) async {
    final auth = _FakeAuthController();
    final sseClient = _IdleMessageSseClient();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        messageServiceProvider.overrideWithValue(_EmptyMessageService()),
        messageSseClientProvider.overrideWithValue(sseClient),
      ],
    );
    container.read(messageRealtimeCoordinatorProvider);

    auth.signIn('user-1');
    await tester.pump(const Duration(milliseconds: 1));
    final firstController = container.read(messageControllerProvider.notifier);
    await firstController.handleRealtimeEvent(
      const MessageRealtimeEvent(
        type: 'message.created',
        message: AppMessage(
          id: 'private-message',
          title: '账号一消息',
          content: '仅账号一可见',
          category: MessageCategory.system,
          isRead: false,
        ),
      ),
    );
    expect(container.read(messageControllerProvider).messages, isNotEmpty);

    auth.signIn('user-2');
    await tester.pump(const Duration(milliseconds: 1));

    final secondController = container.read(messageControllerProvider.notifier);
    expect(identical(firstController, secondController), isFalse);
    expect(container.read(messageControllerProvider).messages, isEmpty);

    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
    await sseClient.close();
  });
}

class _FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthController() : super(const AuthState(isInitialized: true));

  void signIn(String id) {
    state = AuthState(
      isInitialized: true,
      user: AuthUser(
        id: id,
        phone: '13800138000',
        nickname: id,
        avatarUrl: '',
        isVerified: false,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdleMessageSseClient extends MessageSseClient {
  _IdleMessageSseClient() : super(Dio());

  final StreamController<SseEvent> _events = StreamController.broadcast();

  @override
  Stream<SseEvent> connect(CancelToken cancelToken) => _events.stream;

  Future<void> close() => _events.close();
}

class _EmptyMessageService implements MessageServiceContract {
  @override
  Future<ApiResult<MessagePageData>> fetchMessages({
    MessageCategory? category,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async => ApiSuccess(
    MessagePageData(
      items: const [],
      page: page,
      pageSize: pageSize,
      total: 0,
      hasMore: false,
    ),
  );

  @override
  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts() async =>
      const ApiSuccess(MessageUnreadCounts());

  @override
  Future<ApiResult<bool>> markAsRead(String id) async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> markAllAsRead() async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> deleteMessage(String id) async =>
      const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> clearReadMessages() async => const ApiSuccess(true);
}
