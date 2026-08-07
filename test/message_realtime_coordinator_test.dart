import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/message/application/message_realtime_coordinator.dart';
import 'package:zhuxiang_app/features/message/data/realtime/message_sse_client.dart';
import 'package:zhuxiang_app/features/message/data/realtime/sse_event.dart';
import 'package:zhuxiang_app/features/message/domain/entities/message_realtime_event.dart';

void main() {
  testWidgets('coordinator connects for user and dispatches realtime events', (
    tester,
  ) async {
    final client = _FakeMessageSseClient();
    var reconcileCount = 0;
    final received = <MessageRealtimeEvent>[];
    final coordinator = MessageRealtimeCoordinator(
      client: client,
      enabled: true,
      retryDelay: (_) => const Duration(hours: 1),
      onReconcile: () async => reconcileCount++,
      onEvent: (event) async => received.add(event),
    );

    coordinator.updateUser('user-1');
    await tester.pump();
    expect(client.connections, 1);

    client.add(const SseEvent(event: 'connected', data: '{}'));
    await tester.pump();
    expect(reconcileCount, 1);

    client.add(
      const SseEvent(
        id: 'event-1',
        event: 'messages.changed',
        data: '{"eventId":"event-1","operation":"read_all","messageId":null}',
      ),
    );
    await tester.pump();
    expect(received.single.operation, 'read_all');

    coordinator.updateUser(null);
    expect(client.lastCancelToken?.isCancelled, isTrue);
    coordinator.dispose();
    await client.close();
  });

  testWidgets('404 rollout response disables reconnect for current session', (
    tester,
  ) async {
    final client = _DisabledMessageSseClient();
    final coordinator = MessageRealtimeCoordinator(
      client: client,
      enabled: true,
      retryDelay: (_) => const Duration(milliseconds: 1),
      onReconcile: () async {},
      onEvent: (_) async {},
    );

    coordinator.updateUser('user-1');
    await tester.pump(const Duration(seconds: 1));

    expect(client.connections, 1);
    coordinator.dispose();
  });
}

class _FakeMessageSseClient extends MessageSseClient {
  _FakeMessageSseClient() : super(Dio());

  final StreamController<SseEvent> _events = StreamController.broadcast();
  int connections = 0;
  CancelToken? lastCancelToken;

  @override
  Stream<SseEvent> connect(CancelToken cancelToken) {
    connections++;
    lastCancelToken = cancelToken;
    return _events.stream;
  }

  void add(SseEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}

class _DisabledMessageSseClient extends MessageSseClient {
  _DisabledMessageSseClient() : super(Dio());

  int connections = 0;

  @override
  Stream<SseEvent> connect(CancelToken cancelToken) {
    connections++;
    final options = RequestOptions(path: '/messages/stream');
    return Stream.error(
      DioException(
        requestOptions: options,
        response: Response<void>(requestOptions: options, statusCode: 404),
      ),
    );
  }
}
