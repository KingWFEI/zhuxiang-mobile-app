import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/unlock_record.dart';
import '../models/unlock_record_model.dart';

abstract class LockRecordServiceContract {
  Future<UnlockRecordOverview> fetchOverview();
}

class LockRecordService implements LockRecordServiceContract {
  LockRecordService(
    this._apiClient, {
    LockRecordServiceContract? fallback,
    this.allowMockFallback = true,
  }) : _fallback = fallback ?? const MockLockRecordService();

  final ApiClient _apiClient;
  final LockRecordServiceContract _fallback;
  final bool allowMockFallback;

  @override
  Future<UnlockRecordOverview> fetchOverview() async {
    try {
      return await _fetchRemoteOverview();
    } on Object catch (error) {
      if (!allowMockFallback) rethrow;
      AppLogger.debug('LockRecordService fallback to mock: $error');
      return _fallback.fetchOverview();
    }
  }

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

class MockLockRecordService implements LockRecordServiceContract {
  const MockLockRecordService();

  @override
  Future<UnlockRecordOverview> fetchOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    return UnlockRecordOverview(
      lockStatus: CurrentLockStatus(
        houseName: '3栋2单元1201',
        lockName: '客厅智能门锁',
        permissionStatus: LockPermissionStatus.active,
        lastUnlockTime: DateTime(2026, 6, 22, 14, 32),
        supportedMethods: const [
          UnlockMethod.bluetooth,
          UnlockMethod.remote,
          UnlockMethod.password,
        ],
      ),
      records: _mockRecords,
    );
  }
}

final _mockRecords = <UnlockRecord>[
  _record(1, UnlockMethod.bluetooth, UnlockResult.success, 14, 32),
  _record(2, UnlockMethod.remote, UnlockResult.success, 11, 18),
  _record(3, UnlockMethod.password, UnlockResult.success, 9, 5),
  _record(
    4,
    UnlockMethod.admin,
    UnlockResult.success,
    8,
    40,
    operatorName: '小住管家',
    operatorType: UnlockOperatorType.housekeeper,
  ),
  _record(
    5,
    UnlockMethod.bluetooth,
    UnlockResult.failed,
    7,
    52,
    failureReason: '蓝牙连接超时',
  ),
  _record(
    6,
    UnlockMethod.password,
    UnlockResult.failed,
    6,
    30,
    failureReason: '权限已过期',
  ),
  _record(
    7,
    UnlockMethod.remote,
    UnlockResult.failed,
    0,
    18,
    day: 21,
    failureReason: '网络请求超时',
  ),
  _record(
    8,
    UnlockMethod.remote,
    UnlockResult.success,
    19,
    26,
    day: 20,
    operatorName: '平台管理员',
    operatorType: UnlockOperatorType.admin,
  ),
];

UnlockRecord _record(
  int number,
  UnlockMethod method,
  UnlockResult result,
  int hour,
  int minute, {
  int day = 22,
  String operatorName = '王小明',
  UnlockOperatorType operatorType = UnlockOperatorType.tenant,
  String failureReason = '',
}) {
  return UnlockRecord(
    id: 'unlock-${number.toString().padLeft(3, '0')}',
    houseId: 'house-001',
    houseName: '3栋2单元1201',
    lockId: 'lock-001',
    lockName: '客厅智能门锁',
    unlockMethod: method,
    unlockResult: result,
    unlockTime: DateTime(2026, 6, day, hour, minute),
    operatorName: operatorName,
    operatorType: operatorType,
    failureReason: failureReason,
    deviceName: method == UnlockMethod.bluetooth ? 'iPhone 16' : '住享 App',
    remark: result == UnlockResult.success ? '开锁指令执行完成' : '开锁未完成',
  );
}
