import 'package:dio/dio.dart';

import '../storage/storage_service.dart';
import '../utils/app_logger.dart';

typedef OnForceLogout = Future<void> Function();

class ApiInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'lockdata',
    'ekey',
    'password',
    'accesstoken',
    'refreshtoken',
  };

  /// 防止并发刷新 token
  Future<void>? _refreshPromise;

  /// 外部注入的强制登出回调（避免循环引用）
  static OnForceLogout? onForceLogout;

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

    AppLoggerDebug.debug('${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLoggerDebug.debug(
      'HTTP ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isAuthEndpoint(err)) {
      handler.next(err);
      return;
    }

    final opts = err.requestOptions;
    if (opts.extra['_retry'] == true) {
      // 已经重试过一次，不再循环
      handler.next(err);
      return;
    }

    _refreshPromise ??= _doRefresh(err);
    try {
      await _refreshPromise;
      // 刷新成功，用新 token 重试原请求
      final token = await StorageService.tokenStorage.readAccessToken();
      if (token != null) {
        opts.headers['Authorization'] = 'Bearer $token';
        opts.extra['_retry'] = true;
        final response = await _retryRequest(opts);
        handler.resolve(response);
      } else {
        handler.next(err);
      }
    } catch (_) {
      // 刷新失败，清空会话并跳转登录
      AppLoggerDebug.debug('Token refresh failed, redirecting to login');
      await _clearAndRedirect();
      handler.next(err);
    } finally {
      _refreshPromise = null;
    }
  }

  /// 判断是否是认证相关接口（不需要拦截 401）
  bool _isAuthEndpoint(DioException err) {
    final path = err.requestOptions.path;
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/sms-code');
  }

  /// 使用独立 Dio 刷新 token（不经过此 interceptor，避免死循环）
  Future<void> _doRefresh(DioException err) async {
    final tokens = await StorageService.tokenStorage.readTokens();
    if (tokens == null) throw Exception('No refresh token');

    final baseUrl = err.requestOptions.baseUrl.isNotEmpty
        ? err.requestOptions.baseUrl
        : err.requestOptions.uri.origin;
    AppLoggerDebug.debug('Refreshing token using refreshToken: $baseUrl');
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final resp = await dio.post(
      '/auth/refresh',
      data: {'refreshToken': tokens.refreshToken},
    );
    final body = resp.data as Map<String, dynamic>;
    if (body['code'] != 200) throw Exception(body['message'] ?? '刷新失败');

    final data = body['data'] as Map<String, dynamic>;
    await StorageService.tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresIn: data['expiresIn'] as int,
    );
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions opts) async {
    final baseUrl = opts.baseUrl.isNotEmpty ? opts.baseUrl : opts.uri.origin;
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    return dio.request(
      opts.path,
      data: opts.data,
      queryParameters: opts.queryParameters,
      options: Options(
        method: opts.method,
        headers: opts.headers,
        responseType: opts.responseType,
        contentType: opts.contentType,
        receiveTimeout: opts.receiveTimeout,
        sendTimeout: opts.sendTimeout,
        followRedirects: opts.followRedirects,
        receiveDataWhenStatusError: opts.receiveDataWhenStatusError,
      ),
    );
  }

  /// 清除本地会话并跳转登录页
  Future<void> _clearAndRedirect() async {
    await StorageService.tokenStorage.clear();
    if (onForceLogout != null) {
      await onForceLogout!();
    }
  }
}
