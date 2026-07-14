import '../../domain/entities/bill.dart';

class BillModel extends Bill {
  const BillModel({
    required super.id,
    required super.leaseId,
    required super.houseName,
    required super.houseImageUrl,
    required super.periodNo,
    required super.amountDue,
    required super.amountPaid,
    required super.overdueAmount,
    required super.dueDate,
    required super.paidAt,
    required super.status,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: '${json['id'] ?? ''}',
      leaseId: '${json['leaseId'] ?? json['lease_id'] ?? ''}',
      houseName: '${json['houseName'] ?? json['house_name'] ?? ''}',
      houseImageUrl: '${json['houseImageUrl'] ?? json['house_image_url'] ?? ''}',
      periodNo: _int(json['periodNo'] ?? json['period_no']),
      amountDue: _int(json['amountDue'] ?? json['amount_due']),
      amountPaid: _int(json['amountPaid'] ?? json['amount_paid']),
      overdueAmount: _int(json['overdueAmount'] ?? json['overdue_amount']),
      dueDate: DateTime.tryParse('${json['dueDate'] ?? json['due_date'] ?? ''}') ??
          DateTime.now(),
      paidAt: _parseDateTime(json['paidAt'] ?? json['paid_at']),
      status: BillStatus.fromString('${json['status'] ?? 'pending'}'),
    );
  }

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  static DateTime? _parseDateTime(dynamic v) {
    final s = '$v';
    if (s.isEmpty || s == 'null') return null;
    return DateTime.tryParse(s);
  }
}
