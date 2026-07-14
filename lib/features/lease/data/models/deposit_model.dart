import '../../domain/entities/deposit.dart';

class DepositModel {
  const DepositModel(this.json);

  final Map<String, dynamic> json;

  DepositInfo toEntity() {
    final deductions = (json['deductions'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(_deductionFromJson)
            .toList() ??
        const [];

    return DepositInfo(
      id: _str('id'),
      leaseId: _str('leaseId'),
      amount: _int('amount'),
      withheldAmount: _int('withheldAmount'),
      refundedAmount: _int('refundedAmount'),
      status: _str('status'),
      deductions: deductions,
      refundedAt: _date('refundedAt'),
      createdAt: _date('createdAt'),
    );
  }

  DepositDeduction _deductionFromJson(Map<String, dynamic> json) {
    final evidence = json['evidenceUrls'];
    return DepositDeduction(
      id: _strFrom(json, 'id'),
      deductionType: _strFrom(json, 'deductionType'),
      amount: _intFrom(json, 'amount'),
      description: _strFrom(json, 'description'),
      evidenceUrls: evidence is List
          ? evidence.map((e) => e.toString()).toList()
          : const [],
    );
  }

  String _str(String key) => _strFrom(json, key);
  int _int(String key) {
    final v = json[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  DateTime? _date(String key) {
    final v = json[key]?.toString();
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  static String _strFrom(Map<String, dynamic> j, String key) =>
      j[key]?.toString() ?? '';
  static int _intFrom(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
