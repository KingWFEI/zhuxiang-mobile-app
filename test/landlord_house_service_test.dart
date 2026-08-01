import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_exception.dart';
import 'package:zhuxiang_app/core/network/api_result.dart';
import 'package:zhuxiang_app/features/landlord/data/services/landlord_house_service.dart';

void main() {
  test('publish preserves backend message from HTTP failure', () async {
    const backendError = ApiException(
      type: ApiExceptionType.unknown,
      statusCode: 400,
      message: '请先上传房产证后再提交审核',
    );
    final service = LandlordHouseService(
      _FailureApiClient(
        ApiFailure(message: backendError.message, error: backendError),
      ),
    );

    await expectLater(
      service.publishHouse('house-1'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.message, 'message', '请先上传房产证后再提交审核'),
      ),
    );
  });
}

class _FailureApiClient extends ApiClient {
  _FailureApiClient(this.result);

  final ApiResult<Response<dynamic>> result;

  @override
  Future<ApiResult<Response<dynamic>>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return result;
  }
}
