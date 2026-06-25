import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/lease.dart';
import '../models/lease_model.dart';

abstract class LeaseServiceContract {
  Future<List<Lease>> getMyLeases();
  Future<Lease> getLeaseDetail(String leaseId);
  Future<void> renew(String leaseId);
  Future<void> checkout(String leaseId);
}

class LeaseService implements LeaseServiceContract {
  LeaseService(
    this._apiClient, {
    LeaseServiceContract? fallback,
    this.allowMockFallback = true,
  }) : _fallback = fallback ?? MockLeaseService();

  final ApiClient _apiClient;
  final LeaseServiceContract _fallback;
  final bool allowMockFallback;

  @override
  Future<List<Lease>> getMyLeases() {
    return _withFallback(_fetchMyLeases, _fallback.getMyLeases);
  }

  @override
  Future<Lease> getLeaseDetail(String leaseId) {
    return _withFallback(
      () => _fetchLeaseDetail(leaseId),
      () => _fallback.getLeaseDetail(leaseId),
    );
  }

  @override
  Future<void> renew(String leaseId) {
    return _withFallback(
      () => _submitAction(leaseId, 'renew'),
      () => _fallback.renew(leaseId),
    );
  }

  @override
  Future<void> checkout(String leaseId) {
    return _withFallback(
      () => _submitAction(leaseId, 'checkout'),
      () => _fallback.checkout(leaseId),
    );
  }

  Future<List<Lease>> _fetchMyLeases() async {
    final response = await _request(() => _apiClient.get('/leases/my'));
    final payload = _payload(response.data);
    final items = _listPayload(payload);
    return items.map((json) => LeaseModel(json).toEntity()).toList();
  }

  Future<Lease> _fetchLeaseDetail(String leaseId) async {
    final response = await _request(() => _apiClient.get('/leases/$leaseId'));
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '租约详情数据格式错误',
      );
    }
    return LeaseModel(payload).toEntity();
  }

  Future<void> _submitAction(String leaseId, String action) async {
    final response = await _request(
      () => _apiClient.post('/leases/$leaseId/$action'),
    );
    _payload(response.data);
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
    if (code is num && code != 0 && code != 200 && code != 201) {
      throw ApiException(
        type: ApiExceptionType.server,
        message: body['message']?.toString() ?? '租约服务请求失败',
        statusCode: code.toInt(),
      );
    }
    return body.containsKey('data') ? body['data'] : body;
  }

  List<Map<String, dynamic>> _listPayload(dynamic payload) {
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
    return source.whereType<Map<String, dynamic>>().toList();
  }

  Future<T> _withFallback<T>(
    Future<T> Function() remote,
    Future<T> Function() fallback,
  ) async {
    try {
      return await remote();
    } on Object {
      if (!allowMockFallback) rethrow;
      return fallback();
    }
  }
}

class MockLeaseService implements LeaseServiceContract {
  MockLeaseService() : _leases = [_currentLease, _historyLease];

  final List<Lease> _leases;

  @override
  Future<List<Lease>> getMyLeases() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List.unmodifiable(_leases);
  }

  @override
  Future<Lease> getLeaseDetail(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _leases.firstWhere((lease) => lease.id == leaseId);
  }

  @override
  Future<void> renew(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _leases.firstWhere((lease) => lease.id == leaseId);
  }

  @override
  Future<void> checkout(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _leases.indexWhere((lease) => lease.id == leaseId);
    if (index < 0) throw StateError('租约不存在');
    _leases[index] = _leases[index].copyWith(status: LeaseStatus.checkedOut);
  }
}

final _currentLease = Lease(
  id: 'lease-2026-001',
  houseId: 'house-001',
  houseName: '3栋2单元1201',
  houseAddress: '重庆市渝北区中央公园悦居社区',
  houseSummary: '温馨一居 · 42㎡ · 朝南',
  houseImageUrl: '',
  tenantName: '王小明',
  tenantPhone: '13800138000',
  tenantIdCard: '500101199605201234',
  startDate: DateTime(2026, 3, 1),
  endDate: DateTime(2027, 2, 28),
  monthlyRent: 268000,
  deposit: 268000,
  paymentMethod: '押一付一',
  paymentDay: 5,
  status: LeaseStatus.active,
  contractStatus: LeaseContractStatus.signed,
  billStatus: LeaseBillStatus.unpaid,
  lockPermissionStatus: LeaseLockPermissionStatus.active,
  keeperName: '小住管家',
  keeperPhone: '400-800-2026',
  pendingBillTitle: '3月租金待支付',
  pendingBillAmount: 268000,
  pendingBillDueDate: DateTime(2026, 3, 5),
);

final _historyLease = Lease(
  id: 'lease-2025-006',
  houseId: 'house-006',
  houseName: '悦来公寓6栋802',
  houseAddress: '重庆市渝北区悦来大道',
  houseSummary: '精装两居 · 68㎡ · 南北通透',
  houseImageUrl: '',
  tenantName: '王小明',
  tenantPhone: '13800138000',
  tenantIdCard: '500101199605201234',
  startDate: DateTime(2025, 3, 1),
  endDate: DateTime(2026, 2, 28),
  monthlyRent: 320000,
  deposit: 320000,
  paymentMethod: '押一付一',
  paymentDay: 5,
  status: LeaseStatus.expired,
  contractStatus: LeaseContractStatus.signed,
  billStatus: LeaseBillStatus.paid,
  lockPermissionStatus: LeaseLockPermissionStatus.expired,
  keeperName: '小住管家',
  keeperPhone: '400-800-2026',
  pendingBillTitle: '',
  pendingBillAmount: 0,
  pendingBillDueDate: DateTime(2026, 2, 5),
);
