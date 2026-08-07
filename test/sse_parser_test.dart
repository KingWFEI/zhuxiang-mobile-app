import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/message/data/realtime/sse_parser.dart';

void main() {
  test('SSE parser supports split chunks, multiline data and retry', () async {
    final chunks = Stream<List<int>>.fromIterable([
      utf8.encode('event: message.cre'),
      utf8.encode('ated\r\nid: event-1\r\nretry: 3000\r\ndata: first'),
      utf8.encode('\r\ndata: second\r\n\r\n'),
      utf8.encode(': heartbeat comment\n\nevent: heartbeat\ndata: {}\n\n'),
    ]);

    final events = await SseParser.parse(chunks).toList();

    expect(events, hasLength(2));
    expect(events.first.event, 'message.created');
    expect(events.first.id, 'event-1');
    expect(events.first.retry, const Duration(seconds: 3));
    expect(events.first.data, 'first\nsecond');
    expect(events.last.event, 'heartbeat');
  });
}
