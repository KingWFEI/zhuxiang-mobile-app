import 'package:equatable/equatable.dart';

enum BillStatus {
  scheduled('未到期'),
  pending('待支付'),
  paid('已支付'),
  overdue('已逾期'),
  cancelled('已取消');

  const BillStatus(this.label);
  final String label;

  static BillStatus fromString(String value) {
    return BillStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BillStatus.pending,
    );
  }
}

class Bill extends Equatable {
  const Bill({
    required this.id,
    required this.leaseId,
    required this.houseName,
    required this.houseImageUrl,
    required this.periodNo,
    required this.amountDue,
    required this.amountPaid,
    required this.overdueAmount,
    required this.dueDate,
    required this.paidAt,
    required this.status,
  });

  final String id;
  final String leaseId;
  final String houseName;
  final String houseImageUrl;
  final int periodNo;
  final int amountDue;
  final int amountPaid;
  final int overdueAmount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final BillStatus status;

  bool get isPaid => status == BillStatus.paid;
  bool get isOverdue => status == BillStatus.overdue;
  bool get canPay => status == BillStatus.pending || status == BillStatus.overdue;

  @override
  List<Object?> get props => [id, status, amountDue, amountPaid, overdueAmount];
}
