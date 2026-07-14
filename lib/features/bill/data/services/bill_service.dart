import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';

import '../models/bill_model.dart';

class BillService {
  const BillService(this.apiClient);

  final ApiClient apiClient;

  /// 获取我的账单（分组：待付 + 已付）
  Future<BillGroupedResponse> getMyBills() async {
    final result = await apiClient.get('/bills/my');
    return result.unwrapData(BillGroupedResponseModel.fromJson);
  }

  /// 支付账单，返回支付信息
  Future<BillPayResult> payBill(String billId, String channel) async {
    final result = await apiClient.post(
      '/bills/$billId/pay',
      data: {'paymentChannel': channel},
    );
    return result.unwrapData(BillPayResultModel.fromJson);
  }

  /// 主动确认账单支付
  Future<bool> confirmBillPayment(String paymentNo) async {
    final result = await apiClient.post('/bills/$paymentNo/confirm');
    return await result.unwrapValue((data) => data == true);
  }
}

class BillGroupedResponse {
  const BillGroupedResponse({
    required this.scheduledBills,
    required this.pendingBills,
    required this.paidBills,
  });

  final List<BillModel> scheduledBills;
  final List<BillModel> pendingBills;
  final List<BillModel> paidBills;
}

class BillGroupedResponseModel extends BillGroupedResponse {
  const BillGroupedResponseModel({
    required super.scheduledBills,
    required super.pendingBills,
    required super.paidBills,
  });

  factory BillGroupedResponseModel.fromJson(Map<String, dynamic> json) {
    return BillGroupedResponseModel(
      scheduledBills: _parseList(json['scheduledBills'] ?? json['scheduled_bills']),
      pendingBills: _parseList(json['pendingBills'] ?? json['pending_bills']),
      paidBills: _parseList(json['paidBills'] ?? json['paid_bills']),
    );
  }

  static List<BillModel> _parseList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(BillModel.fromJson)
        .toList();
  }
}

class BillPayResult {
  const BillPayResult({
    required this.billId,
    required this.paymentRecordId,
    required this.paymentNo,
    this.payType,
    this.paymentUrl,
    required this.amount,
  });

  final String billId;
  final String paymentRecordId;
  final String paymentNo;
  final String? payType;
  final String? paymentUrl;
  final int amount;

  bool get needWebView => payType == 'h5' && paymentUrl != null;
}

class BillPayResultModel extends BillPayResult {
  const BillPayResultModel({
    required super.billId,
    required super.paymentRecordId,
    required super.paymentNo,
    super.payType,
    super.paymentUrl,
    required super.amount,
  });

  factory BillPayResultModel.fromJson(Map<String, dynamic> json) {
    return BillPayResultModel(
      billId: '${json['billId'] ?? json['bill_id'] ?? ''}',
      paymentRecordId:
          '${json['paymentRecordId'] ?? json['payment_record_id'] ?? ''}',
      paymentNo: '${json['paymentNo'] ?? json['payment_no'] ?? ''}',
      payType: json['payType'] as String? ?? json['pay_type'] as String?,
      paymentUrl:
          json['paymentUrl'] as String? ?? json['payment_url'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}
