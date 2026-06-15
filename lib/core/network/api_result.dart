import 'package:dio/dio.dart';

import 'api_exception.dart';

sealed class ApiResult<T> {
  const ApiResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final message, :final error) => failure(message, error),
    };
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure({required this.message, this.error});

  final String message;
  final Object? error;
}

extension ApiResultUnwrap on ApiResult<Response<dynamic>> {
  Future<T> unwrapValue<T>(T Function(dynamic data) fromData) async {
    return when(
      success: (response) {
        final body = response.data as Map<String, dynamic>;
        final code = body['code'] as int? ?? 0;
        final message = body['message'] as String? ?? '';
        if (code == 200 && body.containsKey('data')) {
          return fromData(body['data']);
        }
        throw ApiException(
          type: ApiExceptionType.server,
          message: message,
          statusCode: code,
        );
      },
      failure: (message, error) {
        throw error is ApiException
            ? error
            : ApiException(
                type: ApiExceptionType.unknown,
                message: message,
                cause: error,
              );
      },
    );
  }

  Future<T> unwrapData<T>(
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    return unwrapValue((data) => fromJson(data as Map<String, dynamic>));
  }
}
