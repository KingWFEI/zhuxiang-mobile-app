import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../models/landlord_contract.dart';

class LandlordContractService {
  const LandlordContractService(this._client);

  final ApiClient _client;

  Future<LandlordContractPage> getPendingContracts({
    required int page,
    required int pageSize,
  }) async {
    final data = _unwrap(
      await _client.get(
        '/landlord/contracts/pending-sign',
        queryParameters: {'page': page, 'pageSize': pageSize},
      ),
    );
    return LandlordContractPage.fromJson(data);
  }

  Future<LandlordContractDetail> getDetail(String orderId) async {
    return LandlordContractDetail.fromJson(
      _unwrap(await _client.get('/landlord/contracts/$orderId')),
    );
  }

  Future<LandlordTerminationPage> getPendingTerminations({
    required int page,
    required int pageSize,
  }) async {
    final data = _unwrap(
      await _client.get(
        '/landlord/termination-applications/pending-sign',
        queryParameters: {'page': page, 'pageSize': pageSize},
      ),
    );
    return LandlordTerminationPage.fromJson(data);
  }

  Future<LandlordTerminationDetail> getTerminationDetail(
    String applicationId,
  ) async {
    return LandlordTerminationDetail.fromJson(
      _unwrap(
        await _client.get('/landlord/termination-applications/$applicationId'),
      ),
    );
  }

  Future<RescissionSignResult> signTermination(String applicationId) async {
    return RescissionSignResult.fromJson(
      _unwrap(
        await _client.post(
          '/landlord/termination-applications/$applicationId/rescission-sign-url',
        ),
      ),
    );
  }

  Future<RescissionSignResult> refreshTermination(String applicationId) async {
    return RescissionSignResult.fromJson(
      _unwrap(
        await _client.post(
          '/landlord/termination-applications/$applicationId/refresh',
        ),
      ),
    );
  }

  Future<EsignResult> sign(String orderId) async {
    return EsignResult.fromJson(
      _unwrap(await _client.post('/landlord/contracts/$orderId/sign')),
    );
  }

  Future<void> reject(String orderId, String reason) async {
    final result = await _client.post(
      '/landlord/contracts/$orderId/reject',
      data: {'reason': reason},
    );
    if (result case ApiSuccess<Response<dynamic>>(:final data)) {
      final body = data.data;
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        final code = map['code'];
        if (code == 200 || code == 0 || code == '200' || code == '0') return;
        throw ApiException(
          type: ApiExceptionType.server,
          message: map['message']?.toString() ?? '拒绝签署失败',
          statusCode: data.statusCode,
          businessCode: code?.toString(),
        );
      }
    }
    if (result case ApiFailure<Response<dynamic>>(
      :final error,
      :final message,
    )) {
      if (error is ApiException) throw error;
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: message,
        cause: error,
      );
    }
    throw const ApiException(type: ApiExceptionType.server, message: '拒绝签署失败');
  }

  Future<ContractSignStatus> refresh(String orderId) async {
    return ContractSignStatus.fromJson(
      _unwrap(await _client.post('/landlord/contracts/$orderId/refresh')),
    );
  }

  Map<String, dynamic> _unwrap(ApiResult<Response<dynamic>> result) {
    if (result case ApiSuccess<Response<dynamic>>(:final data)) {
      final body = data.data;
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        final code = map['code'] as int? ?? -1;
        if (code == 200 || code == 0) {
          final payload = map['data'];
          if (payload is Map) return Map<String, dynamic>.from(payload);
        }
        throw ApiException(
          type: code == 401
              ? ApiExceptionType.unauthorized
              : ApiExceptionType.server,
          message: map['message']?.toString() ?? '请求失败',
          statusCode: code,
        );
      }
    }
    if (result case ApiFailure<Response<dynamic>>(
      :final error,
      :final message,
    )) {
      if (error is ApiException) throw error;
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: message,
        cause: error,
      );
    }
    throw const ApiException(type: ApiExceptionType.server, message: '请求失败');
  }
}
