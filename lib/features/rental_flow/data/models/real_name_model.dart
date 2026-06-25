class RealNameModel {
  const RealNameModel({
    required this.name,
    required this.idCardNumber,
    required this.phone,
  });

  final String name;
  final String idCardNumber;
  final String phone;

  Map<String, dynamic> toJson() => {
    'tenantName': name,
    'tenantPhone': phone,
    'tenantIdCard': idCardNumber,
  };
}
