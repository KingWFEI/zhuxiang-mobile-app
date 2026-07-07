import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';
import 'api_result.dart';

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? AppConfig.baseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
            ),
          ) {
    _dio.interceptors.add(ApiInterceptor());
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<ApiResult<Response<dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<ApiResult<Response<dynamic>>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<ApiResult<Response<dynamic>>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<ApiResult<Response<dynamic>>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<ApiResult<Response<dynamic>>> _request(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return ApiSuccess(response);
    } on DioException catch (error) {
      final exception = _mapDioException(error);
      return ApiFailure(message: exception.message, error: exception);
    } on Object catch (error) {
      return ApiFailure(
        message: 'Unknown network error',
        error: ApiException(
          type: ApiExceptionType.unknown,
          message: 'Unknown network error',
          cause: error,
        ),
      );
    }
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final responseMessage = responseData is Map<String, dynamic>
        ? responseData['message'] as String?
        : null;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException(
        type: ApiExceptionType.timeout,
        message: 'Request timeout',
        statusCode: statusCode,
        cause: error,
      );
    }

    if (statusCode == 401) {
      return ApiException(
        type: ApiExceptionType.unauthorized,
        message: responseMessage ?? 'Unauthorized request',
        statusCode: statusCode,
        cause: error,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        type: ApiExceptionType.server,
        message: responseMessage ?? 'Server error',
        statusCode: statusCode,
        cause: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        type: ApiExceptionType.network,
        message: 'Network connection error',
        statusCode: statusCode,
        cause: error,
      );
    }

    return ApiException(
      type: ApiExceptionType.unknown,
      message: responseMessage ?? error.message ?? 'Unknown network error',
      statusCode: statusCode,
      cause: error,
    );
  }
}
