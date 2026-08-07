import 'dart:convert';

import '../../data/realtime/sse_event.dart';
import 'app_message.dart';

class MessageRealtimeEvent {
  const MessageRealtimeEvent({
    required this.type,
    this.eventId,
    this.operation,
    this.messageId,
    this.message,
  });

  final String type;
  final String? eventId;
  final String? operation;
  final String? messageId;
  final AppMessage? message;

  factory MessageRealtimeEvent.fromSse(SseEvent event) {
    final type = event.event ?? '';
    if (event.data.isEmpty) {
      return MessageRealtimeEvent(type: type, eventId: event.id);
    }
    final decoded = jsonDecode(event.data);
    if (decoded is! Map) {
      throw const FormatException('实时消息事件格式错误');
    }
    final json = Map<String, dynamic>.from(decoded);
    final rawMessage = json['message'];
    return MessageRealtimeEvent(
      type: type.isNotEmpty ? type : json['type']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? event.id,
      operation: json['operation']?.toString(),
      messageId: json['messageId']?.toString(),
      message: rawMessage is Map
          ? AppMessage.fromJson(Map<String, dynamic>.from(rawMessage))
          : null,
    );
  }
}
