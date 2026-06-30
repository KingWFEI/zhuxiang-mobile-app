class LeaseContractDocument {
  const LeaseContractDocument({
    required this.id,
    required this.contractNo,
    required this.houseName,
    required this.tenantName,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.paymentMethod,
    required this.statusText,
    required this.content,
    required this.fileUrl,
    required this.clauses,
    required this.signedAt,
  });

  final String id;
  final String contractNo;
  final String houseName;
  final String tenantName;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int deposit;
  final String paymentMethod;
  final String statusText;
  final String content;
  final String fileUrl;
  final List<String> clauses;
  final DateTime? signedAt;
}
