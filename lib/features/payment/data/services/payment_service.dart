import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/payment_record.dart';

class PaymentService {
  const PaymentService(this._apiClient);

  final ApiClient _apiClient;

  Future<PaymentRecordPageResult> fetchMyPayments({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.get(
      '/payments/my',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return result.unwrapValue(_parsePageResult);
  }

  Future<PaymentRecord> fetchPaymentDetail(String paymentId) async {
    final result = await _apiClient.get('/payments/$paymentId');
    return result.unwrapData(_parsePaymentRecord);
  }

  PaymentRecordPageResult _parsePageResult(dynamic data) {
    final payload = data is Map<String, dynamic> ? data : const {};
    final source =
        payload['items'] ??
        payload['records'] ??
        payload['rows'] ??
        payload['content'] ??
        payload['list'] ??
        const <dynamic>[];
    final items = source is List
        ? source
              .whereType<Map<String, dynamic>>()
              .map(_parsePaymentRecord)
              .toList(growable: false)
        : const <PaymentRecord>[];
    return PaymentRecordPageResult(
      items: items,
      page: _int(payload['page'], fallback: 1),
      pageSize: _int(payload['pageSize'] ?? payload['page_size'], fallback: 20),
      hasMore: payload['hasMore'] as bool? ?? false,
      total: _int(payload['total'], fallback: items.length),
    );
  }

  PaymentRecord _parsePaymentRecord(Map<String, dynamic> json) {
    return PaymentRecord(
      id: _string(json, ['id', 'paymentId']),
      paymentNo: _string(json, ['paymentNo', 'payment_no']),
      houseName: _string(json, ['houseName', 'house_name'], fallback: '未知房源'),
      orderId: _nullableString(json, ['orderId', 'order_id']),
      leaseId: _nullableString(json, ['leaseId', 'lease_id']),
      billId: _nullableString(json, ['billId', 'bill_id']),
      type: PaymentRecordType.fromValue(json['type']),
      amount: _int(json['amount']),
      paymentChannel: _string(json, ['paymentChannel', 'payment_channel']),
      channelTradeNo: _string(json, [
        'channelTradeNo',
        'channel_trade_no',
        'transactionNo',
      ]),
      status: PaymentRecordStatus.fromValue(json['status']),
      remark: _string(json, ['remark']),
      paidAt: _date(json['paidAt'] ?? json['paid_at']),
      createdAt:
          _date(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
    );
  }

  String _string(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String? _nullableString(Map<String, dynamic> json, List<String> keys) {
    final value = _string(json, keys);
    return value.isEmpty ? null : value;
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime? _date(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}
