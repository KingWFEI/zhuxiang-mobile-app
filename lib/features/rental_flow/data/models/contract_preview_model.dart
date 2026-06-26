import '../../domain/entities/contract_preview.dart';

class ContractPreviewModel extends ContractPreview {
  const ContractPreviewModel({
    required super.orderId,
    required super.contractNo,
    required super.houseName,
    required super.tenantName,
    required super.landlordName,
    required super.startDate,
    required super.endDate,
    required super.monthlyRent,
    required super.deposit,
    required super.paymentMethod,
    required super.clauses,
  });

  factory ContractPreviewModel.fromJson(Map<String, dynamic> json) {
    return ContractPreviewModel(
      orderId: '${json['orderId'] ?? json['order_id'] ?? ''}',
      contractNo:
          json['contractNo'] as String? ?? json['contract_no'] as String? ?? '',
      houseName:
          json['houseName'] as String? ??
          json['house_name'] as String? ??
          '租住房源',
      tenantName:
          json['tenantName'] as String? ??
          json['tenant_name'] as String? ??
          '租客',
      landlordName:
          json['landlordName'] as String? ??
          json['landlord_name'] as String? ??
          '平台房东',
      startDate:
          DateTime.tryParse(
            '${json['startDate'] ?? json['start_date'] ?? ''}',
          ) ??
          DateTime.now(),
      endDate:
          DateTime.tryParse('${json['endDate'] ?? json['end_date'] ?? ''}') ??
          DateTime.now(),
      monthlyRent: _centsToYuan(
        json['monthlyRent'] as num? ?? json['monthly_rent'] as num? ?? 0,
      ),
      deposit: _centsToYuan(json['deposit'] as num? ?? 0),
      paymentMethod: _paymentMethodLabel(
        json['paymentMethod'] as String? ??
            json['payment_method'] as String? ??
            'monthly',
      ),
      clauses: (json['clauses'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .toList(),
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
