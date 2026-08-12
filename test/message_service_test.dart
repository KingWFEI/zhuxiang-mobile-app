import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/message/data/services/message_service.dart';
import 'package:zhuxiang_app/features/message/domain/entities/app_message.dart';

void main() {
  test('退款成功消息在账单分类中保留 none 动作和订单目标', () {
    final message = AppMessage.fromJson({
      'id': 'message-refund-1',
      'category': 'bill',
      'title': '退款成功',
      'content': '租房订单退款已原路退回，退款金额为2800.00元。',
      'isRead': false,
      'actionType': 'none',
      'actionTarget': 'order-1',
    });

    expect(message.category, MessageCategory.bill);
    expect(message.actionType, 'none');
    expect(message.actionTarget, 'order-1');
  });
  test(
    'fetchMessages uses backend path and exact query parameter names',
    () async {
      final client = _RecordingApiClient(
        responseData: {
          'code': 200,
          'message': 'success',
          'data': {
            'items': [
              {
                'id': 'message-1',
                'title': '报修已受理',
                'content': '维修人员将尽快联系您',
                'category': 'repair',
                'isRead': false,
                'createdAt': '2026-06-30T08:00:00.000Z',
                'iconKey': 'repair',
                'actionType': 'repair',
                'actionTarget': 'repair-1',
              },
            ],
            'page': 2,
            'pageSize': 20,
            'total': 21,
            'hasMore': false,
          },
        },
      );
      final service = MessageService(client);

      final result = await service.fetchMessages(
        category: MessageCategory.repair,
        isRead: false,
        page: 2,
        pageSize: 20,
      );

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/messages');
      expect(client.lastQuery, {
        'category': 'repair',
        'isRead': false,
        'page': 2,
        'pageSize': 20,
      });
      expect(result, isA<ApiSuccess<MessagePageData>>());
      final data = (result as ApiSuccess<MessagePageData>).data;
      expect(data.items.single.id, 'message-1');
      expect(data.items.single.category, MessageCategory.repair);
      expect(data.hasMore, isFalse);
    },
  );

  test('unread and mutation methods use documented backend paths', () async {
    final client = _RecordingApiClient(
      responseData: {
        'code': 200,
        'message': 'success',
        'data': {
          'appointment': 1,
          'bill': 2,
          'lease': 3,
          'lock': 4,
          'repair': 5,
          'system': 6,
          'total': 21,
        },
      },
    );
    final service = MessageService(client);

    final countsResult = await service.fetchUnreadCounts();
    expect(client.lastPath, '/messages/unread-counts');
    expect((countsResult as ApiSuccess<MessageUnreadCounts>).data.total, 21);

    client.responseData = {'code': 200, 'message': 'success', 'data': true};
    await service.markAsRead('message-1');
    expect(
      (client.lastMethod, client.lastPath),
      ('PUT', '/messages/message-1/read'),
    );

    await service.markAllAsRead();
    expect((client.lastMethod, client.lastPath), ('PUT', '/messages/read-all'));
    expect(client.lastQuery, isNull);

    await service.deleteMessage('message-1');
    expect(
      (client.lastMethod, client.lastPath),
      ('DELETE', '/messages/message-1'),
    );

    await service.clearReadMessages();
    expect((client.lastMethod, client.lastPath), ('DELETE', '/messages/read'));
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({required this.responseData})
    : super(baseUrl: 'https://example.test/api');

  dynamic responseData;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastQuery;

  @override
  Future<ApiResult<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _respond('GET', path, queryParameters);
  }

  @override
  Future<ApiResult<Response<dynamic>>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _respond('PUT', path, queryParameters);
  }

  @override
  Future<ApiResult<Response<dynamic>>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _respond('DELETE', path, queryParameters);
  }

  ApiResult<Response<dynamic>> _respond(
    String method,
    String path,
    Map<String, dynamic>? query,
  ) {
    lastMethod = method;
    lastPath = path;
    lastQuery = query;
    return ApiSuccess(
      Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        data: responseData,
        statusCode: 200,
      ),
    );
  }
}
