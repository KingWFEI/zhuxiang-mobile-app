import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/cs_entities.dart';

class CustomerServiceApi {
  const CustomerServiceApi(this._apiClient);

  final ApiClient _apiClient;
  static const _base = '/customer-service';

  Future<ApiResult<CsSession>> createSession() async {
    final result = await _apiClient.post('$_base/sessions');
    return _mapSingle(result, CsSession.fromJson);
  }

  Future<ApiResult<EnterSessionResponse>> enterSession() async {
    final result = await _apiClient.post('$_base/sessions/enter');
    return _mapSingle(result, EnterSessionResponse.fromJson);
  }

  Future<ApiResult<List<CsSession>>> getSessions(
      {int page = 1, int pageSize = 20}) async {
    final result = await _apiClient.get('$_base/sessions',
        queryParameters: {'page': page, 'pageSize': pageSize});
    return _mapPage(result, CsSession.fromJson);
  }

  Future<ApiResult<List<CsMessage>>> getMessages(String sessionId) async {
    final result = await _apiClient.get('$_base/sessions/$sessionId/messages');
    return _mapList(result, CsMessage.fromJson);
  }

  Future<ApiResult<void>> closeSession(String sessionId) async {
    final result = await _apiClient.post('$_base/sessions/$sessionId/close');
    if (result case ApiFailure(:final message))
      return ApiFailure(message: message);
    return const ApiSuccess(null);
  }

  Future<ApiResult<void>> submitFeedback(
      {required String messageId,
      required String type,
      String? comment}) async {
    final result = await _apiClient.post(
      '$_base/messages/$messageId/feedback',
      data: {'feedbackType': type, 'comment': comment},
    );
    if (result case ApiFailure(:final message))
      return ApiFailure(message: message);
    return const ApiSuccess(null);
  }

  // ── SSE 流式聊天 ──

  Stream<SseEvent> streamMessage({
    required String sessionId,
    required String message,
  }) async* {
    try {
      // 用 Dio 直接发请求（receiveTimeout=0 确保长连接不中途断开）
      final response = await _apiClient.dio.post(
        '$_base/sessions/$sessionId/messages/stream',
        data: {'message': message},
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data;
      if (stream is! ResponseBody) {
        yield SseEvent(
            event: 'error',
            data: jsonEncode({'message': '响应异常'}));
        return;
      }

      String buf = '';
      await for (final chunk in stream.stream) {
        buf += utf8.decode(chunk);
        // SSE 按 \n\n 分隔事件
        while (buf.contains('\n\n')) {
          final idx = buf.indexOf('\n\n');
          final block = buf.substring(0, idx);
          buf = buf.substring(idx + 2);

          String eventType = '';
          final dataLines = <String>[];
          for (final line in block.split('\n')) {
            final t = line.trim();
            if (t.startsWith('event:')) {
              eventType = t.substring(6).trim();
            } else if (t.startsWith('data:')) {
              dataLines.add(t.substring(5).trim());
            }
          }
          if (eventType.isNotEmpty && dataLines.isNotEmpty) {
            yield SseEvent(event: eventType, data: dataLines.join('\n'));
          }
        }
      }
    } on DioException catch (e) {
      yield SseEvent(
          event: 'error',
          data: jsonEncode({'message': e.message ?? '连接失败'}));
    } catch (e) {
      yield SseEvent(
          event: 'error',
          data: jsonEncode({'message': '连接异常'}));
    }
  }

  // ── 内部解析 ──

  ApiResult<T> _mapSingle<T>(
      ApiResult<Response> result, T Function(Map<String, dynamic>) parser) {
    return _unwrap(result, (data) => parser(Map<String, dynamic>.from(data)));
  }

  ApiResult<List<T>> _mapList<T>(
      ApiResult<Response> result, T Function(Map<String, dynamic>) parser) {
    return _unwrap(result, (data) {
      if (data is List) {
        return data.map((e) => parser(Map<String, dynamic>.from(e))).toList();
      }
      return <T>[];
    });
  }

  ApiResult<List<T>> _mapPage<T>(
      ApiResult<Response> result, T Function(Map<String, dynamic>) parser) {
    return _unwrap(result, (data) {
      final map = Map<String, dynamic>.from(data);
      final items = map['items'];
      if (items is List) {
        return items.map((e) => parser(Map<String, dynamic>.from(e))).toList();
      }
      return <T>[];
    });
  }

  ApiResult<T> _unwrap<T>(
      ApiResult<Response> result, T Function(dynamic data) parser) {
    if (result case ApiFailure(:final message, :final error)) {
      return ApiFailure<T>(message: message, error: error);
    }
    try {
      final body = (result as ApiSuccess<Response>).data.data;
      if (body is! Map) return ApiFailure<T>(message: '响应格式错误');
      final code = body['code'];
      if (code != 200) {
        return ApiFailure<T>(
            message: body['message']?.toString() ?? '请求失败');
      }
      return ApiSuccess(parser(body['data']));
    } on Object catch (e) {
      return ApiFailure<T>(message: '数据解析失败', error: e);
    }
  }
}

class SseEvent {
  const SseEvent({required this.event, required this.data});
  final String event;
  final String data;

  Map<String, dynamic>? get jsonData {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
