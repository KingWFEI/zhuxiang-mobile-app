enum ApiExceptionType { timeout, unauthorized, server, network, unknown }

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.retryAfter,
    this.cause,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final int? retryAfter;
  final Object? cause;

  @override
  String toString() {
    return 'ApiException(type: $type, statusCode: $statusCode, retryAfter: $retryAfter, message: $message)';
  }
}
