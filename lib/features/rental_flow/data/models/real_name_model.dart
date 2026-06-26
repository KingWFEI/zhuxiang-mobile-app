class RealNameModel {
  const RealNameModel({
    required this.name,
    required this.idCardNumber,
    required this.phone,
    required this.idCardFrontUrl,
    required this.idCardBackUrl,
  });

  final String name;
  final String idCardNumber;
  final String phone;
  final String idCardFrontUrl;
  final String idCardBackUrl;

  Map<String, dynamic> toJson() => {
    'tenantName': name,
    'tenantPhone': phone,
    'tenantIdCard': idCardNumber,
    'idCardFrontUrl': idCardFrontUrl,
    'idCardBackUrl': idCardBackUrl,
  };
}
