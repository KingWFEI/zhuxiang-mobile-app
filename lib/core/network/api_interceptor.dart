import 'package:dio/dio.dart';

import '../storage/storage_service.dart';
import '../utils/logger.dart';

class ApiInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'lockdata',
    'ekey',
    'password',
    'accesstoken',
    'refreshtoken',
  };

  /// 供任何 Dio 调试日志统一脱敏；unlock-data 的 lockData 永不输出明文。
  static Object? sanitizeForLog(Object? value) {
    if (value is Map) {
      return value.map((key, item) {
        final normalized = key.toString().replaceAll('_', '').toLowerCase();
        return MapEntry(
          key,
          _sensitiveKeys.contains(normalized)
              ? '[REDACTED]'
              : sanitizeForLog(item),
        );
      });
    }
    if (value is List) return value.map(sanitizeForLog).toList();
    return value;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    AppLogger.debug('${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // 响应正文默认不记录；如以后开启 body 日志，必须先调用 sanitizeForLog。
    AppLogger.debug(
      'HTTP ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      AppLogger.debug('Unauthorized request reserved for auth flow handling');
    }

    handler.next(err);
  }
}
