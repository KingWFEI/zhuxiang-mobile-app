import '../../domain/entities/contract_preview.dart';

class ContractPreviewModel extends ContractPreview {
  const ContractPreviewModel({
    required super.orderId,
    required super.contractNo,
    required super.houseName,
    required super.tenantName,
    required super.landlordName,
    super.landlordPhone,
    super.landlordIdCard,
    required super.startDate,
    required super.endDate,
    required super.monthlyRent,
    required super.deposit,
    required super.paymentMethod,
    required super.clauses,
    super.content,
  });

  factory ContractPreviewModel.fromJson(Map<String, dynamic> json) {
    final source = _nestedContract(json);
    final clauses = _stringList(
      source['clauses'] ?? source['contractClauses'] ?? json['clauses'],
    );
    final content = _string(
      source['content'] ??
          source['contractContent'] ??
          source['contract_content'] ??
          source['text'] ??
          json['content'],
    );

    return ContractPreviewModel(
      orderId: _string(
        source['orderId'] ?? source['order_id'] ?? json['orderId'],
      ),
      contractNo: _string(
        source['contractNo'] ?? source['contract_no'] ?? json['contractNo'],
      ),
      houseName: _string(
        source['houseName'] ?? source['house_name'],
        fallback: 'Rental property',
      ),
      tenantName: _string(
        source['tenantName'] ?? source['tenant_name'],
        fallback: 'Tenant',
      ),
      landlordName: _string(
        source['landlordName'] ?? source['landlord_name'],
        fallback: 'Landlord',
      ),
      landlordPhone: _string(
        source['landlordPhone'] ?? source['landlord_phone'],
      ),
      landlordIdCard: _string(
        source['landlordIdCard'] ?? source['landlord_id_card'],
      ),
      startDate: _date(source['startDate'] ?? source['start_date']),
      endDate: _date(source['endDate'] ?? source['end_date']),
      monthlyRent: _amount(source['monthlyRent'] ?? source['monthly_rent']),
      deposit: _amount(source['deposit'] ?? source['depositAmount']),
      paymentMethod: _paymentMethodLabel(
        _string(
          source['paymentMethod'] ?? source['payment_method'],
          fallback: 'monthly',
        ),
      ),
      clauses: clauses,
      content: content.isNotEmpty ? content : clauses.join('\n\n'),
    );
  }
}

Map<String, dynamic> _nestedContract(Map<String, dynamic> json) {
  final nested =
      json['contract'] ?? json['contractInfo'] ?? json['contract_info'];
  return nested is Map<String, dynamic> ? {...json, ...nested} : json;
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

DateTime _date(Object? value) =>
    DateTime.tryParse(_string(value)) ?? DateTime.now();

int _amount(Object? value) {
  final number = switch (value) {
    num numeric => numeric.toDouble(),
    String text => double.tryParse(text.trim()) ?? 0,
    _ => 0,
  };
  return (number / 100).round();
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => _string(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(RegExp(r'\r?\n|;'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

String _paymentMethodLabel(String value) {
  return switch (value.toLowerCase()) {
    'monthly' => '月付',
    'quarterly' => '季付',
    'semi_annual' => '半年付',
    'annual' => '年付',
    _ => value,
  };
}
