import '../../domain/entities/rent_order.dart';

class RentOrderModel extends RentOrder {
  const RentOrderModel({
    required super.id,
    required super.orderNo,
    required super.houseId,
    required super.houseName,
    required super.roomName,
    required super.address,
    required super.coverUrl,
    required super.startDate,
    required super.leaseMonths,
    required super.paymentMethod,
    required super.tenantCount,
    required super.monthlyRent,
    required super.deposit,
    required super.serviceFee,
    required super.firstPaymentAmount,
    required super.status,
  });

  factory RentOrderModel.fromJson(Map<String, dynamic> json) {
    return RentOrderModel(
      id: '${json['id'] ?? ''}',
      orderNo: json['orderNo'] as String? ?? json['order_no'] as String? ?? '',
      houseId: '${json['houseId'] ?? json['house_id'] ?? ''}',
      houseName:
          json['houseName'] as String? ??
          json['house_name'] as String? ??
          '租住房源',
      roomName:
          json['roomName'] as String? ?? json['room_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      coverUrl:
          json['coverUrl'] as String? ?? json['cover_url'] as String? ?? '',
      startDate:
          DateTime.tryParse(
            '${json['startDate'] ?? json['start_date'] ?? ''}',
          ) ??
          DateTime.now(),
      leaseMonths:
          (json['leaseMonths'] as num? ?? json['lease_months'] as num? ?? 12)
              .toInt(),
      paymentMethod: _paymentMethodLabel(
        json['paymentMethod'] as String? ??
            json['payment_method'] as String? ??
            'monthly',
      ),
      tenantCount:
          (json['tenantCount'] as num? ?? json['tenant_count'] as num? ?? 1)
              .toInt(),
      monthlyRent: _centsToYuan(
        json['monthlyRent'] as num? ?? json['monthly_rent'] as num? ?? 0,
      ),
      deposit: _centsToYuan(json['deposit'] as num? ?? 0),
      serviceFee: _centsToYuan(
        json['serviceFee'] as num? ?? json['service_fee'] as num? ?? 0,
      ),
      firstPaymentAmount: _centsToYuan(
        json['firstPaymentAmount'] as num? ??
            json['first_payment_amount'] as num? ??
            0,
      ),
      status: _parseStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNo': orderNo,
    'houseId': houseId,
    'houseName': houseName,
    'roomName': roomName,
    'address': address,
    'coverUrl': coverUrl,
    'startDate': startDate.toIso8601String(),
    'leaseMonths': leaseMonths,
    'paymentMethod': paymentMethod,
    'tenantCount': tenantCount,
    'monthlyRent': monthlyRent,
    'deposit': deposit,
    'serviceFee': serviceFee,
    'firstPaymentAmount': firstPaymentAmount,
    'status': status.name,
  };

  static RentOrderStatus _parseStatus(String? value) {
    return RentOrderStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => RentOrderStatus.created,
    );
  }
}

int _centsToYuan(num value) => (value / 100).round();

String _paymentMethodLabel(String value) {
  return switch (value) {
    'monthly' || '押一付一' || '月付' => '月付',
    'quarterly' || '押一付三' || '季付' => '季付',
    'semi_annual' || '押一付六' || '半年付' => '半年付',
    'annual' || '押一付十二' || '年付' => '年付',
    _ => value,
  };
}
