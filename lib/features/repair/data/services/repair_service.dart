import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../../lease/data/models/lease_model.dart';
import '../../../lease/domain/entities/lease.dart';
import '../../domain/entities/repair_order.dart';
import '../models/repair_order_model.dart';

const noActiveRepairLeaseMessage = '暂无有效租房合同';

abstract class RepairServiceContract {
  Future<RepairOverview> fetchOverview();
  Future<RepairOrder> fetchRepairDetail(String repairId);
  Future<RepairOrder> createRepair(CreateRepairRequest request);
  Future<RepairOrder> submitReview({
    required String repairId,
    required int rating,
    required String content,
  });
  Future<RepairOrder> cancelRepair(String repairId);
}

class RepairService implements RepairServiceContract {
  RepairService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<RepairOverview> fetchOverview() => _fetchRemoteOverview();

  @override
  Future<RepairOrder> fetchRepairDetail(String repairId) async {
    final response = await _request(() => _apiClient.get('/repairs/$repairId'));
    return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
  }

  @override
  Future<RepairOrder> createRepair(CreateRepairRequest request) async {
    final response = await _request(
      () => _apiClient.post('/repairs', data: repairRequestToJson(request)),
    );
    return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
  }

  @override
  Future<RepairOrder> submitReview({
    required String repairId,
    required int rating,
    required String content,
  }) async {
    final response = await _request(
      () => _apiClient.post(
        '/repairs/$repairId/review',
        data: {'rating': rating, 'reviewContent': content},
      ),
    );
    return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
  }

  @override
  Future<RepairOrder> cancelRepair(String repairId) async {
    final response = await _request(
      () => _apiClient.post('/repairs/$repairId/cancel'),
    );
    return RepairOrderModel(_firstMap(_payload(response.data))).toEntity();
  }

  Future<RepairOverview> _fetchRemoteOverview() async {
    final responses = await Future.wait([
      _request(() => _apiClient.get('/repairs/my')),
      _request(() => _apiClient.get('/leases/my')),
    ]);
    final repairsPayload = _payload(responses[0].data);
    final leasePayload = _payload(responses[1].data);
    final orders = _list(
      repairsPayload,
    ).map((json) => RepairOrderModel(json).toEntity()).toList();
    final leases = _leaseList(
      leasePayload,
    ).map((json) => LeaseModel(json).toEntity()).toList();
    final repairHouses = _repairLeases(
      leases,
    ).map(_repairHouseFromLease).toList(growable: false);
    return RepairOverview(
      currentHouse: repairHouses.first,
      availableHouses: repairHouses,
      orders: orders,
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
        message: body['message']?.toString() ?? '报修服务请求失败',
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
      message: '报修数据格式错误',
    );
  }

  List<Map<String, dynamic>> _list(dynamic payload) {
    dynamic source = payload;
    if (payload is Map<String, dynamic>) {
      source = payload['items'] ?? payload['records'] ?? payload['list'];
    }
    if (source is! List) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '报修列表数据格式错误',
      );
    }
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _leaseList(dynamic payload) {
    dynamic source = payload;
    if (payload is Map<String, dynamic>) {
      source =
          payload['items'] ??
          payload['records'] ??
          payload['rows'] ??
          payload['content'] ??
          payload['list'] ??
          payload['leases'];
      if (source == null) {
        final current =
            payload['current'] ??
            payload['currentLease'] ??
            payload['currentLeases'] ??
            payload['activeLease'] ??
            payload['activeLeases'];
        final history =
            payload['history'] ??
            payload['historical'] ??
            payload['historyLease'] ??
            payload['historyLeases'] ??
            payload['historicalLeases'];
        source = [
          if (current is Map<String, dynamic>) current,
          if (current is List) ...current,
          if (history is Map<String, dynamic>) history,
          if (history is List) ...history,
        ];
      }
    }
    if (source == null && payload is Map<String, dynamic>) {
      source = [payload];
    }
    if (source is! List) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '租约列表数据格式错误',
      );
    }
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Lease> _repairLeases(List<Lease> leases) {
    if (leases.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: noActiveRepairLeaseMessage,
      );
    }
    final activeLeases = leases
        .where((lease) => lease.status == LeaseStatus.active)
        .toList(growable: false);
    if (activeLeases.isNotEmpty) return activeLeases;
    throw const ApiException(
      type: ApiExceptionType.server,
      message: noActiveRepairLeaseMessage,
    );
  }

  RepairHouse _repairHouseFromLease(Lease lease) {
    return RepairHouse(
      houseId: lease.houseId,
      houseName: lease.houseName,
      roomName: lease.houseName,
      leaseStatus: lease.status.label,
      housekeeperName: lease.keeperName,
      housekeeperPhone: lease.keeperPhone,
    );
  }
}
