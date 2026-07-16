import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/real_name_auth_models.dart';

class RealNameAuthApi {
  const RealNameAuthApi(this.apiClient);

  final ApiClient apiClient;

  Future<RealNameAuthStatusResponse> getStatus() async {
    final result = await apiClient.get('/real-name-auth/status');
    return _read(result, RealNameAuthStatusResponse.fromJson);
  }

  Future<RealNameAuthStartResponse> start({
    required String realName,
    required String idCardNo,
  }) async {
    final result = await apiClient.post(
      '/real-name-auth/start',
      data: {
        'realName': realName,
        'idCardType': 'INDIVIDUAL_CH_IDCARD',
        'idCardNo': idCardNo,
      },
    );
    return _read(result, RealNameAuthStatusResponse.fromJson);
  }

  Future<RealNameAuthStartResponse> restart({
    required String realName,
    required String idCardNo,
  }) async {
    final result = await apiClient.post(
      '/real-name-auth/restart',
      data: {
        'realName': realName,
        'idCardType': 'INDIVIDUAL_CH_IDCARD',
        'idCardNo': idCardNo,
      },
    );
    return _read(result, RealNameAuthStatusResponse.fromJson);
  }

  Future<RealNameAuthRefreshResponse> refresh(String realNameAuthNo) async {
    final result = await apiClient.post(
      '/real-name-auth/$realNameAuthNo/refresh',
    );
    return _read(result, RealNameAuthStatusResponse.fromJson);
  }

  Future<T> _read<T>(
    ApiResult<Response<dynamic>> result,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return result.unwrapData(fromJson);
  }
}
