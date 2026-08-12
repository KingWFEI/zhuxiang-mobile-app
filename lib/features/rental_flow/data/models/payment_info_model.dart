import '../../domain/entities/payment_info.dart';

class PaymentInfoModel extends PaymentInfo {
  const PaymentInfoModel({
    required super.orderId,
    required super.amount,
    required super.monthlyRent,
    required super.paymentMonths,
    required super.deposit,
    required super.serviceFee,
    required super.paymentMethods,
    super.selectedPaymentMethod,
    super.payType,
    super.paymentUrl,
  });

  factory PaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentInfoModel(
      orderId: '${json['orderId'] ?? json['order_id'] ?? ''}',
      amount: _centsToYuan(json['amount'] as num? ?? 0),
      monthlyRent: _centsToYuan(
        json['monthlyRent'] as num? ?? json['monthly_rent'] as num? ?? 0,
      ),
      paymentMonths:
          (json['paymentMonths'] as num? ?? json['payment_months'] as num? ?? 1)
              .toInt(),
      deposit: _centsToYuan(json['deposit'] as num? ?? 0),
      serviceFee: _centsToYuan(
        json['serviceFee'] as num? ?? json['service_fee'] as num? ?? 0,
      ),
      paymentMethods:
          (json['paymentMethods'] as List<dynamic>? ??
                  json['payment_methods'] as List<dynamic>? ??
                  const ['微信支付', '支付宝', '银行卡'])
              .map((item) => '$item')
              .toList(),
      selectedPaymentMethod:
          json['selectedPaymentMethod'] as String? ??
          json['selected_payment_method'] as String?,
      payType: json['payType'] as String? ?? json['pay_type'] as String?,
      paymentUrl:
          json['paymentUrl'] as String? ?? json['payment_url'] as String?,
    );
  }
}

int _centsToYuan(num value) => (value / 100).round();
