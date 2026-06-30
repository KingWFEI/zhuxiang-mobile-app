import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_message.dart';

abstract class MessageServiceContract {
  Future<ApiResult<MessagePageData>> fetchMessages({
    MessageCategory? category,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  });

  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts();
  Future<ApiResult<bool>> markAsRead(String id);
  Future<ApiResult<bool>> markAllAsRead();
  Future<ApiResult<bool>> deleteMessage(String id);
  Future<ApiResult<bool>> clearReadMessages();
}

class MessageService implements MessageServiceContract {
  const MessageService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<MessagePageData>> fetchMessages({
    MessageCategory? category,
    bool? isRead,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (category != null) query['category'] = category.apiValue;
    if (isRead != null) query['isRead'] = isRead;

    final result = await _apiClient.get(
      ApiEndpoints.messages,
      queryParameters: query,
    );
    return _mapResponse(result, (data) {
      if (data is! Map) throw const FormatException('消息列表数据格式错误');
      return MessagePageData.fromJson(Map<String, dynamic>.from(data));
    });
  }

  @override
  Future<ApiResult<MessageUnreadCounts>> fetchUnreadCounts() async {
    final result = await _apiClient.get(
      '${ApiEndpoints.messages}/unread-counts',
    );
    return _mapResponse(result, (data) {
      if (data is! Map) throw const FormatException('未读消息数据格式错误');
      return MessageUnreadCounts.fromJson(Map<String, dynamic>.from(data));
    });
  }

  @override
  Future<ApiResult<bool>> markAsRead(String id) async {
    final result = await _apiClient.put('${ApiEndpoints.messages}/$id/read');
    return _mapResponse(result, (data) => data == true);
  }

  @override
  Future<ApiResult<bool>> markAllAsRead() async {
    final result = await _apiClient.put('${ApiEndpoints.messages}/read-all');
    return _mapResponse(result, (data) => data == true);
  }

  @override
  Future<ApiResult<bool>> deleteMessage(String id) async {
    final result = await _apiClient.delete('${ApiEndpoints.messages}/$id');
    return _mapResponse(result, (data) => data == true);
  }

  @override
  Future<ApiResult<bool>> clearReadMessages() async {
    final result = await _apiClient.delete('${ApiEndpoints.messages}/read');
    return _mapResponse(result, (data) => data == true);
  }

  ApiResult<T> _mapResponse<T>(
    ApiResult<Response<dynamic>> result,
    T Function(dynamic data) parse,
  ) {
    if (result case ApiFailure<Response<dynamic>>(
      :final message,
      :final error,
    )) {
      return ApiFailure<T>(message: message, error: error);
    }

    try {
      final response = (result as ApiSuccess<Response<dynamic>>).data;
      final body = response.data;
      if (body is! Map) {
        return ApiFailure<T>(message: '消息服务响应格式错误');
      }
      final json = Map<String, dynamic>.from(body);
      final code = json['code'];
      if (code != 200) {
        return ApiFailure<T>(
          message: json['message']?.toString() ?? '消息服务请求失败',
        );
      }
      return ApiSuccess<T>(parse(json['data']));
    } on Object catch (error) {
      return ApiFailure<T>(message: '消息数据解析失败', error: error);
    }
  }
}
