import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/unlock_record.dart';
import '../models/unlock_record_model.dart';

abstract class LockRecordServiceContract {
  Future<UnlockRecordOverview> fetchOverview();
}

class LockRecordService implements LockRecordServiceContract {
  LockRecordService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<UnlockRecordOverview> fetchOverview() => _fetchRemoteOverview();

  Future<UnlockRecordOverview> _fetchRemoteOverview() async {
    final results = await Future.wait([
      _request(() => _apiClient.get('/locks/my-permissions')),
      _request(() => _apiClient.get('/locks/unlock-records/my')),
    ]);
    final permissionPayload = _payload(results[0].data);
    final recordPayload = _payload(results[1].data);
    final permissionJson = _firstMap(permissionPayload);
    final records = _list(
      recordPayload,
    ).map((json) => UnlockRecordModel(json).toEntity()).toList();
    return UnlockRecordOverview(
      lockStatus: CurrentLockStatusModel(permissionJson).toEntity(),
      records: records,
    );
  }

  Future<Response<dynamic>> _request(
    Future<ApiResult<Response<dynamic>>> Function() request,
  ) async {
    final result = await request();
    return result.when(
      success: (response) => response,
      failure: (message, error) => throw error is ApiException
          ? error
          : ApiException(
              type: ApiExceptionType.unknown,
              message: message,
              cause: error,
            ),
    );
  }

  dynamic _payload(dynamic body) {
    if (body is! Map<String, dynamic>) return body;
    final code = body['code'];
    if (code is num && code != 0 && code != 200) {
      throw ApiException(
        type: ApiExceptionType.server,
        message: body['message']?.toString() ?? '开门记录请求失败',
        statusCode: code.toInt(),
      );
    }
    return body.containsKey('data') ? body['data'] : body;
  }

  Map<String, dynamic> _firstMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final source = payload['items'] ?? payload['records'] ?? payload['list'];
      if (source is List && source.isNotEmpty && source.first is Map) {
        return Map<String, dynamic>.from(source.first as Map);
      }
      return payload;
    }
    if (payload is List && payload.isNotEmpty && payload.first is Map) {
      return Map<String, dynamic>.from(payload.first as Map);
    }
    throw const ApiException(
      type: ApiExceptionType.server,
      message: '门锁权限数据格式错误',
    );
  }

  List<Map<String, dynamic>> _list(dynamic payload) {
    dynamic source = payload;
    if (payload is Map<String, dynamic>) {
      source =
          payload['items'] ??
          payload['records'] ??
          payload['list'] ??
          payload['unlockRecords'];
    }
    if (source is! List) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '开门记录数据格式错误',
      );
    }
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
