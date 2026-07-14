import '../../domain/entities/pay_result.dart';

class PayResultModel extends PayResult {
  const PayResultModel({
    required super.orderId,
    required super.paymentRecordId,
    super.payType,
    super.paymentUrl,
    required super.orderStatus,
    required super.paymentNo,
    required super.amount,
  });

  factory PayResultModel.fromJson(Map<String, dynamic> json) {
    return PayResultModel(
      orderId: '${json['orderId'] ?? json['order_id'] ?? ''}',
      paymentRecordId:
          '${json['paymentRecordId'] ?? json['payment_record_id'] ?? ''}',
      payType: json['payType'] as String? ?? json['pay_type'] as String?,
      paymentUrl:
          json['paymentUrl'] as String? ?? json['payment_url'] as String?,
      orderStatus:
          '${json['orderStatus'] ?? json['order_status'] ?? ''}',
      paymentNo: '${json['paymentNo'] ?? json['payment_no'] ?? ''}',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}
