class LandlordContractItem {
  const LandlordContractItem({
    required this.orderId,
    required this.contractId,
    required this.contractNo,
    required this.contractStatus,
    required this.tenantSigned,
    required this.lessorSigned,
    required this.signStage,
    required this.houseId,
    required this.houseName,
    required this.roomName,
    required this.address,
    required this.tenantName,
    required this.tenantPhone,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.updatedAt,
  });

  final String orderId;
  final String contractId;
  final String contractNo;
  final String contractStatus;
  final bool tenantSigned;
  final bool lessorSigned;
  final String signStage;
  final String houseId;
  final String houseName;
  final String roomName;
  final String address;
  final String tenantName;
  final String tenantPhone;
  final String startDate;
  final String endDate;
  final int monthlyRent;
  final int deposit;
  final String updatedAt;

  factory LandlordContractItem.fromJson(Map<String, dynamic> json) {
    return LandlordContractItem(
      orderId: _string(json['orderId']),
      contractId: _string(json['contractId']),
      contractNo: _string(json['contractNo']),
      contractStatus: _string(json['contractStatus']),
      tenantSigned: _bool(json['tenantSigned']),
      lessorSigned: _bool(json['lessorSigned']),
      signStage: _string(json['signStage']),
      houseId: _string(json['houseId']),
      houseName: _string(json['houseName']),
      roomName: _string(json['roomName']),
      address: _string(json['address']),
      tenantName: _string(json['tenantName']),
      tenantPhone: _string(json['tenantPhone']),
      startDate: _string(json['startDate']),
      endDate: _string(json['endDate']),
      monthlyRent: _int(json['monthlyRent']),
      deposit: _int(json['deposit']),
      updatedAt: _string(json['updatedAt']),
    );
  }
}

class LandlordContractPage {
  const LandlordContractPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.total,
  });

  final List<LandlordContractItem> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int total;

  factory LandlordContractPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return LandlordContractPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (e) => LandlordContractItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
      page: _int(json['page']),
      pageSize: _int(json['pageSize']),
      hasMore: _bool(json['hasMore']),
      total: _int(json['total']),
    );
  }
}

class LandlordContractDetail {
  const LandlordContractDetail({
    required this.orderId,
    required this.contractId,
    required this.contractStatus,
    required this.tenantSigned,
    required this.lessorSigned,
    required this.signStage,
    required this.contract,
  });

  final String orderId;
  final String contractId;
  final String contractStatus;
  final bool tenantSigned;
  final bool lessorSigned;
  final String signStage;
  final ContractPreview contract;

  bool get canSign {
    final status = contractStatus.toLowerCase();
    return !lessorSigned &&
        status != 'signed' &&
        status != 'completed' &&
        status != 'cancelled' &&
        status != 'canceled' &&
        status != 'expired';
  }

  bool get unavailable {
    final status = contractStatus.toLowerCase();
    return status == 'cancelled' || status == 'canceled' || status == 'expired';
  }

  factory LandlordContractDetail.fromJson(Map<String, dynamic> json) {
    final contract = json['contract'];
    return LandlordContractDetail(
      orderId: _string(json['orderId']),
      contractId: _string(json['contractId']),
      contractStatus: _string(json['contractStatus']),
      tenantSigned: _bool(json['tenantSigned']),
      lessorSigned: _bool(json['lessorSigned']),
      signStage: _string(json['signStage']),
      contract: ContractPreview.fromJson(
        contract is Map ? Map<String, dynamic>.from(contract) : const {},
      ),
    );
  }
}

class ContractPreview {
  const ContractPreview({
    required this.contractNo,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantIdCard,
    required this.houseName,
    required this.roomName,
    required this.houseAddress,
    required this.landlordName,
    required this.landlordPhone,
    required this.landlordIdCard,
    required this.startDate,
    required this.endDate,
    required this.leaseMonths,
    required this.monthlyRent,
    required this.deposit,
    required this.serviceFee,
    required this.paymentMethod,
    required this.paymentMonths,
    required this.clauses,
  });

  final String contractNo;
  final String tenantName;
  final String tenantPhone;
  final String tenantIdCard;
  final String houseName;
  final String roomName;
  final String houseAddress;
  final String landlordName;
  final String landlordPhone;
  final String landlordIdCard;
  final String startDate;
  final String endDate;
  final int leaseMonths;
  final int monthlyRent;
  final int deposit;
  final int serviceFee;
  final String paymentMethod;
  final int paymentMonths;
  final List<String> clauses;

  factory ContractPreview.fromJson(Map<String, dynamic> json) {
    return ContractPreview(
      contractNo: _string(json['contractNo']),
      tenantName: _string(json['tenantName']),
      tenantPhone: _string(json['tenantPhone']),
      tenantIdCard: _string(json['tenantIdCard']),
      houseName: _string(json['houseName']),
      roomName: _string(json['roomName']),
      houseAddress: _string(json['houseAddress']),
      landlordName: _string(json['landlordName']),
      landlordPhone: _string(json['landlordPhone']),
      landlordIdCard: _string(json['landlordIdCard']),
      startDate: _string(json['startDate']),
      endDate: _string(json['endDate']),
      leaseMonths: _int(json['leaseMonths']),
      monthlyRent: _int(json['monthlyRent']),
      deposit: _int(json['deposit']),
      serviceFee: _int(json['serviceFee']),
      paymentMethod: _string(json['paymentMethod']),
      paymentMonths: _int(json['paymentMonths']),
      clauses:
          (json['clauses'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class EsignResult {
  const EsignResult({
    required this.contractStatus,
    required this.currentUserSigned,
    required this.signUrl,
  });

  final String contractStatus;
  final bool currentUserSigned;
  final String signUrl;

  factory EsignResult.fromJson(Map<String, dynamic> json) => EsignResult(
    contractStatus: _string(json['contractStatus']),
    currentUserSigned: _bool(json['currentUserSigned']),
    signUrl: _string(json['signUrl']),
  );
}

class ContractSignStatus {
  const ContractSignStatus({
    required this.contractStatus,
    required this.lessorSigned,
    required this.tenantSigned,
    required this.currentUserSigned,
    required this.downloadAvailable,
    required this.signedAt,
  });

  final String contractStatus;
  final bool lessorSigned;
  final bool tenantSigned;
  final bool currentUserSigned;
  final bool downloadAvailable;
  final String signedAt;

  bool get completed => contractStatus.toUpperCase() == 'COMPLETED';

  factory ContractSignStatus.fromJson(Map<String, dynamic> json) =>
      ContractSignStatus(
        contractStatus: _string(json['contractStatus']),
        lessorSigned: _bool(json['lessorSigned']),
        tenantSigned: _bool(json['tenantSigned']),
        currentUserSigned: _bool(json['currentUserSigned']),
        downloadAvailable: _bool(json['downloadAvailable']),
        signedAt: _string(json['signedAt']),
      );
}

String formatContractMoney(int cents) {
  final parts = (cents / 100).toStringAsFixed(2).split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '¥$buffer.${parts.last}';
}

String maskIdCard(String value) {
  if (value.length < 8) return value;
  return '${value.substring(0, 4)}**********${value.substring(value.length - 4)}';
}

String _string(dynamic value) => value?.toString() ?? '';
int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(_string(value)) ?? 0;
bool _bool(dynamic value) =>
    value == true || value == 1 || _string(value).toLowerCase() == 'true';
