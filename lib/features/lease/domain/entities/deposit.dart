class DepositInfo {
  const DepositInfo({
    required this.id,
    required this.leaseId,
    required this.amount,
    required this.withheldAmount,
    required this.refundedAmount,
    required this.status,
    required this.deductions,
    this.refundedAt,
    this.createdAt,
  });

  final String id;
  final String leaseId;
  final int amount;
  final int withheldAmount;
  final int refundedAmount;
  final String status;
  final List<DepositDeduction> deductions;
  final DateTime? refundedAt;
  final DateTime? createdAt;

  int get pendingAmount => amount - withheldAmount - refundedAmount;

  String get statusLabel {
    return switch (status) {
      'held' => '托管中',
      'deducted' => '已扣款',
      'refunding' => '退款中',
      'refunded' => '已退款',
      _ => status,
    };
  }

  int get statusIndex {
    return switch (status) {
      'held' => 0,
      'deducted' => 1,
      'refunding' => 2,
      'refunded' => 3,
      _ => 0,
    };
  }
}

class DepositDeduction {
  const DepositDeduction({
    required this.id,
    required this.deductionType,
    required this.amount,
    required this.description,
    required this.evidenceUrls,
  });

  final String id;
  final String deductionType;
  final int amount;
  final String description;
  final List<String> evidenceUrls;

  String get typeLabel {
    return switch (deductionType) {
      'cleaning' => '保洁费',
      'damage' => '维修费',
      'unpaid_bill' => '欠费扣款',
      'bill_arrears' => '欠费扣款',
      'rent_arrears' => '欠租扣款',
      'other' => '其他扣款',
      _ => deductionType,
    };
  }
}
