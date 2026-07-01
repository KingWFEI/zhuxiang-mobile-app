import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/lease_contract_document.dart';
import '../../domain/entities/lease_termination.dart';
import '../models/lease_model.dart';

abstract class LeaseServiceContract {
  Future<List<Lease>> getMyLeases();
  Future<Lease> getLeaseDetail(String leaseId);
  Future<LeaseContractDocument> getLeaseContract(String leaseId);
  Future<void> renew(String leaseId);
  Future<LeaseTerminationAttachment> uploadTerminationAttachment({
    required String filePath,
    required String fileName,
  });
  Future<TerminationApplication?> getCurrentTermination(String leaseId);
  Future<TerminationCheck> checkTermination(String leaseId);
  Future<TerminationApplication> applyTermination(
    String leaseId,
    Map<String, dynamic> body,
  );
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
  Future<LeaseContractDocument> getLeaseContract(String leaseId) {
    return _withFallback(
      () => _fetchLeaseContract(leaseId),
      () => _fallback.getLeaseContract(leaseId),
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
  Future<LeaseTerminationAttachment> uploadTerminationAttachment({
    required String filePath,
    required String fileName,
  }) {
    return _uploadTerminationAttachment(filePath: filePath, fileName: fileName);
  }

  @override
  Future<TerminationApplication?> getCurrentTermination(String leaseId) {
    return _fetchCurrentTermination(leaseId);
  }

  @override
  Future<TerminationCheck> checkTermination(String leaseId) {
    return _withFallback(
      () => _checkTermination(leaseId),
      () => _fallback.checkTermination(leaseId),
    );
  }

  @override
  Future<TerminationApplication> applyTermination(
    String leaseId,
    Map<String, dynamic> body,
  ) {
    return _withFallback(
      () => _applyTermination(leaseId, body),
      () => _fallback.applyTermination(leaseId, body),
    );
  }

  Future<List<Lease>> _fetchMyLeases() async {
    final response = await _request(() => _apiClient.get('/leases/my'));
    final payload = _payload(response.data);
    final items = _listPayload(payload);
    return items.map((json) => LeaseModel(json).toEntity()).toList();
  }

  Future<Lease> _fetchLeaseDetail(String leaseId) async {
    final response = await _request(
      () => _apiClient.get('/leases/$leaseId'),
    );
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '租约详情数据格式错误',
      );
    }
    return LeaseModel(payload).toEntity();
  }

  Future<LeaseContractDocument> _fetchLeaseContract(String leaseId) async {
    final response = await _request(
      () => _apiClient.get('/leases/$leaseId/contract'),
    );
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '电子合同数据格式错误',
      );
    }
    return _contractFromJson(payload);
  }

  Future<void> _submitAction(String leaseId, String action) async {
    final response = await _request(
      () => _apiClient.post('/leases/$leaseId/$action'),
    );
    _payload(response.data);
  }

  Future<LeaseTerminationAttachment> _uploadTerminationAttachment({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _request(
      () => _apiClient.post(
        '/files/upload',
        data: formData,
        queryParameters: {'bizType': 'lease_termination'},
      ),
    );
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '附件上传数据格式错误',
      );
    }
    final url = _string(payload, ['url', 'fileUrl', 'file_url']);
    if (url.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '附件上传失败，请重试',
      );
    }
    return LeaseTerminationAttachment(
      url: url,
      type: _string(payload, ['type', 'fileType'], fallback: 'image'),
      name: _string(payload, [
        'name',
        'fileName',
        'originalName',
      ], fallback: fileName),
    );
  }

  Future<TerminationApplication?> _fetchCurrentTermination(
    String leaseId,
  ) async {
    final response = await _request(
      () => _apiClient.get('/leases/$leaseId/termination/current'),
    );
    final payload = _payload(response.data);
    if (payload == null) return null;
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '退租申请数据格式错误',
      );
    }
    return TerminationApplication.fromJson(payload);
  }

  Future<TerminationCheck> _checkTermination(String leaseId) async {
    final response = await _request(
      () => _apiClient.get('/leases/$leaseId/termination/check'),
    );
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '退租检查数据格式错误',
      );
    }
    return TerminationCheck.fromJson(payload);
  }

  Future<TerminationApplication> _applyTermination(
    String leaseId,
    Map<String, dynamic> body,
  ) async {
    final response = await _request(
      () => _apiClient.post('/leases/$leaseId/termination/apply', data: body),
    );
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '退租申请数据格式错误',
      );
    }
    return TerminationApplication.fromJson(payload);
  }

  LeaseContractDocument _contractFromJson(Map<String, dynamic> json) {
    final contract = _map(json['contract'] ?? json['contractInfo']);
    final source = contract.isEmpty ? json : contract;
    return LeaseContractDocument(
      id: _string(source, ['id', 'contractId', 'contract_id']),
      contractNo: _string(source, [
        'contractNo',
        'contract_no',
        'no',
      ], fallback: '暂无编号'),
      houseName: _string(source, [
        'houseName',
        'house_name',
        'roomName',
      ], fallback: _string(json, ['houseName', 'house_name'])),
      tenantName: _string(source, [
        'tenantName',
        'tenant_name',
      ], fallback: _string(json, ['tenantName', 'tenant_name'])),
      startDate: _date(source, [
        'startDate',
        'start_date',
        'leaseStartDate',
      ], fallback: _date(json, ['startDate', 'start_date'])),
      endDate: _date(source, [
        'endDate',
        'end_date',
        'leaseEndDate',
      ], fallback: _date(json, ['endDate', 'end_date'])),
      monthlyRent: _money(source, [
        'monthlyRent',
        'monthly_rent',
        'rentAmount',
      ], fallback: _money(json, ['monthlyRent', 'monthly_rent'])),
      deposit: _money(source, [
        'deposit',
        'depositAmount',
        'deposit_amount',
      ], fallback: _money(json, ['deposit', 'depositAmount'])),
      paymentMethod: _string(source, [
        'paymentMethod',
        'payment_method',
      ], fallback: _string(json, ['paymentMethod', 'payment_method'])),
      statusText: _string(source, [
        'statusText',
        'status_text',
        'contractStatusText',
      ], fallback: '已签约'),
      content: _string(source, [
        'content',
        'contractContent',
        'contract_content',
        'text',
      ]),
      fileUrl: _string(source, ['fileUrl', 'file_url', 'url', 'pdfUrl']),
      clauses: _stringList(source['clauses'] ?? source['contractClauses']),
      signedAt: _nullableDate(source, ['signedAt', 'signed_at', 'signTime']),
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

  static String _string(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map<String, dynamic> ? value : const {};
  }

  static int _integer(
    Map<String, dynamic> source,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static int _money(
    Map<String, dynamic> source,
    List<String> keys, {
    int fallback = 0,
  }) {
    final value = _integer(source, keys, fallback: fallback);
    if (value <= 0 || value >= 100000) return value;
    return value * 100;
  }

  static DateTime _date(
    Map<String, dynamic> source,
    List<String> keys, {
    DateTime? fallback,
  }) {
    for (final key in keys) {
      final parsed = DateTime.tryParse(source[key]?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback ?? DateTime(2026, 3, 1);
  }

  static DateTime? _nullableDate(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final parsed = DateTime.tryParse(source[key]?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static List<String> _stringList(dynamic source) {
    if (source is! List) return const [];
    return source
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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
  Future<LeaseContractDocument> getLeaseContract(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final lease = _leases.firstWhere((lease) => lease.id == leaseId);
    return LeaseContractDocument(
      id: 'contract-$leaseId',
      contractNo: 'HT202603010001',
      houseName: lease.houseName,
      tenantName: lease.tenantName,
      startDate: lease.startDate,
      endDate: lease.endDate,
      monthlyRent: lease.monthlyRent,
      deposit: lease.deposit,
      paymentMethod: lease.paymentMethod,
      statusText: lease.contractStatus.label,
      content: '',
      fileUrl: '',
      clauses: [
        '甲乙双方确认房源信息：${lease.houseName}，地址为${lease.houseAddress}。',
        '租赁期限：自${_formatDate(lease.startDate)}起至${_formatDate(lease.endDate)}止。',
        '租金及支付方式：月租金为人民币${_formatMoney(lease.monthlyRent)}元，押金为人民币${_formatMoney(lease.deposit)}元，付款方式为${lease.paymentMethod}。',
        '房屋用途：承租方承诺该房屋仅作为居住使用，不得擅自转租或改变用途。',
        '合同解除：提前解除合同需按合同约定完成申请、验房、结算和押金处理。',
      ],
      signedAt: DateTime(2026, 3, 1),
    );
  }

  @override
  Future<void> renew(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _leases.firstWhere((lease) => lease.id == leaseId);
  }

  @override
  Future<LeaseTerminationAttachment> uploadTerminationAttachment({
    required String filePath,
    required String fileName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return LeaseTerminationAttachment(
      url: 'mock://lease-termination/$fileName',
      type: 'image',
      name: fileName,
    );
  }

  @override
  Future<TerminationApplication?> getCurrentTermination(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return null;
  }

  @override
  Future<TerminationCheck> checkTermination(String leaseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const TerminationCheck(
      canApply: true,
      hasPendingApplication: false,
      hasUnpaidBills: false,
      message: '',
    );
  }

  @override
  Future<TerminationApplication> applyTermination(
    String leaseId,
    Map<String, dynamic> body,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _leases.firstWhere((lease) => lease.id == leaseId);
    return const TerminationApplication(
      id: 'termination-2026-001',
      applicationNo: 'TZ202606290001',
      status: 'pending_review',
      statusText: '待审核',
    );
  }
}

final _currentLease = Lease(
  id: 'lease-2026-001',
  contractId: 'contract-2026-001',
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
  contractId: 'contract-2025-006',
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

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}

String _formatMoney(int amount) {
  return (amount / 100).toStringAsFixed(amount % 100 == 0 ? 0 : 2);
}
