import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/lease.dart';
import '../../domain/entities/lease_contract_document.dart';
import '../../domain/entities/lease_termination.dart';
import '../../domain/entities/deposit.dart';
import '../models/deposit_model.dart';
import '../models/lease_model.dart';

abstract class LeaseServiceContract {
  Future<List<Lease>> getMyLeases();
  Future<Lease> getLeaseDetail(String leaseId);
  Future<DepositInfo?> getDeposit(String leaseId);
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
  Future<RescissionActionLink> getRescissionSignUrl(String applicationId);
}

class LeaseService implements LeaseServiceContract {
  LeaseService(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Lease>> getMyLeases() => _fetchMyLeases();

  @override
  Future<Lease> getLeaseDetail(String leaseId) => _fetchLeaseDetail(leaseId);

  @override
  Future<DepositInfo?> getDeposit(String leaseId) {
    return _fetchDeposit(leaseId);
  }

  @override
  Future<LeaseContractDocument> getLeaseContract(String leaseId) =>
      _fetchLeaseContract(leaseId);

  @override
  Future<void> renew(String leaseId) => _submitAction(leaseId, 'renew');

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
  Future<TerminationCheck> checkTermination(String leaseId) =>
      _checkTermination(leaseId);

  @override
  Future<TerminationApplication> applyTermination(
    String leaseId,
    Map<String, dynamic> body,
  ) => _applyTermination(leaseId, body);

  @override
  Future<RescissionActionLink> getRescissionSignUrl(
    String applicationId,
  ) async {
    final response = await _request(
      () => _apiClient.post(
        '/leases/termination-applications/$applicationId/rescission-sign-url',
      ),
    );
    final payload = _payload(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '解约签署链接数据格式错误',
      );
    }
    final url = _string(payload, ['signUrl', 'url', 'shortUrl']);
    if (url.isEmpty) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '未获取到解约协议签署链接',
      );
    }
    return RescissionActionLink(
      action: _string(payload, ['action'], fallback: 'sign'),
      url: url,
    );
  }

  Future<List<Lease>> _fetchMyLeases() async {
    final response = await _request(() => _apiClient.get('/leases/my'));
    final payload = _payload(response.data);
    final items = _listPayload(payload);
    return items.map((json) => LeaseModel(json).toEntity()).toList();
  }

  Future<DepositInfo?> _fetchDeposit(String leaseId) async {
    final response = await _request(
      () => _apiClient.get('/deposits/my/$leaseId'),
    );
    final payload = _payload(response.data);
    if (payload == null) return null;
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: '押金数据格式错误',
      );
    }
    return DepositModel(payload).toEntity();
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
      ]),
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
    if (fallback != null) return fallback;
    throw FormatException('Missing required date field: ${keys.join(', ')}');
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
}
