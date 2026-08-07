import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/message/application/message_controller.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';
import 'package:zhuxiang_app/features/message/domain/entities/message_realtime_event.dart';

void main() {
  test(
    'created realtime event prepends once and changed event updates it',
    () async {
      final service = _FakeMessageService();
      final controller = MessageController(service);
      addTearDown(controller.dispose);
      await controller.loadInitial();

      const message = AppMessage(
        id: 'message-1',
        title: '预约已确认',
        content: '请按预约时间到场',
        category: MessageCategory.appointment,
        isRead: false,
      );
      const created = MessageRealtimeEvent(
        type: 'message.created',
        eventId: 'event-1',
        messageId: 'message-1',
        message: message,
      );

      await controller.handleRealtimeEvent(created);
      await controller.handleRealtimeEvent(created);

      expect(controller.state.messages, hasLength(1));
      expect(controller.state.total, 1);
      expect(controller.state.messages.single.isRead, isFalse);

      await controller.handleRealtimeEvent(
        const MessageRealtimeEvent(
          type: 'messages.changed',
          operation: 'read',
          messageId: 'message-1',
        ),
      );
      expect(controller.state.messages.single.isRead, isTrue);
    },
  );
}

class _FakeMessageService implements MessageServiceContract {
  @override
  Future<ApiResult<MessagePageData>> fetchMessages({
    MessageCategory? category,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    return ApiSuccess(
      MessagePageData(
        items: const [],
        page: page,
        pageSize: pageSize,
        total: 0,
        hasMore: false,
      ),
    );
  }

  @override
  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts() async {
    return const ApiSuccess(MessageUnreadCounts());
  }

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
