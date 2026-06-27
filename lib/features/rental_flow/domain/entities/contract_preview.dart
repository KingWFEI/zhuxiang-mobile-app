class ContractPreview {
  const ContractPreview({
    required this.orderId,
    required this.contractNo,
    required this.houseName,
    required this.tenantName,
    required this.landlordName,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.paymentMethod,
    required this.clauses,
    this.content = '',
  });

  final String orderId;
  final String contractNo;
  final String houseName;
  final String tenantName;
  final String landlordName;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int deposit;
  final String paymentMethod;
  final List<String> clauses;
  final String content;
}
