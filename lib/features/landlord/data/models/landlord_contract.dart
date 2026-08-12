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

class LandlordTerminationItem {
  const LandlordTerminationItem({
    required this.applicationId,
    required this.applicationNo,
    required this.status,
    required this.statusText,
    required this.contractId,
    required this.contractNo,
    required this.houseName,
    required this.roomName,
    required this.address,
    required this.tenantName,
    required this.tenantPhone,
    required this.expectedMoveOutDate,
    required this.tenantSigned,
    required this.lessorSigned,
    required this.updatedAt,
  });

  final String applicationId;
  final String applicationNo;
  final String status;
  final String statusText;
  final String contractId;
  final String contractNo;
  final String houseName;
  final String roomName;
  final String address;
  final String tenantName;
  final String tenantPhone;
  final String expectedMoveOutDate;
  final bool tenantSigned;
  final bool lessorSigned;
  final String updatedAt;

  /// 只有后端已经创建真实退租申请且进入电子解约阶段，才属于房东待签。
  /// 防止普通租赁合同或空占位数据被误展示成“解约协议”。
  bool get isValidPendingSignature {
    final normalizedStatus = status.trim().toLowerCase();
    return applicationId.trim().isNotEmpty &&
        applicationNo.trim().isNotEmpty &&
        contractId.trim().isNotEmpty &&
        (normalizedStatus == 'rescission_pending' ||
            normalizedStatus == 'rescission_signing');
  }

  factory LandlordTerminationItem.fromJson(Map<String, dynamic> json) {
    return LandlordTerminationItem(
      applicationId: _string(json['applicationId'] ?? json['id']),
      applicationNo: _string(json['applicationNo']),
      status: _string(json['status']),
      statusText: _string(json['statusText']),
      contractId: _string(json['contractId']),
      contractNo: _string(json['contractNo']),
      houseName: _string(json['houseName']),
      roomName: _string(json['roomName']),
      address: _string(json['address']),
      tenantName: _string(json['tenantName']),
      tenantPhone: _string(json['tenantPhone']),
      expectedMoveOutDate: _string(json['expectedMoveOutDate']),
      tenantSigned: _bool(json['tenantSigned']),
      lessorSigned: _bool(json['lessorSigned']),
      updatedAt: _string(json['updatedAt']),
    );
  }
}

class LandlordTerminationPage {
  const LandlordTerminationPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.total,
  });

  final List<LandlordTerminationItem> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int total;

  factory LandlordTerminationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => LandlordTerminationItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.isValidPendingSignature)
              .toList()
        : const <LandlordTerminationItem>[];
    return LandlordTerminationPage(
      items: parsedItems,
      page: _int(json['page']),
      pageSize: _int(json['pageSize']),
      hasMore: _bool(json['hasMore']),
      // 首屏若包含后端误返回的空占位数据，待签角标也必须随之扣除。
      total:
          (_int(json['total']) -
                  ((rawItems is List ? rawItems.length : 0) -
                      parsedItems.length))
              .clamp(0, 1 << 31),
    );
  }
}

class LandlordTerminationDetail {
  const LandlordTerminationDetail({
    required this.item,
    required this.reason,
    required this.actualMoveOutDate,
    required this.refundAmount,
    required this.deductionAmount,
  });

  final LandlordTerminationItem item;
  final String reason;
  final String actualMoveOutDate;
  final int refundAmount;
  final int deductionAmount;

  bool get canSign =>
      !item.lessorSigned &&
      item.status != 'rescission_completed' &&
      item.status != 'completed' &&
      item.status != 'cancelled' &&
      item.status != 'rejected';

  factory LandlordTerminationDetail.fromJson(Map<String, dynamic> json) {
    final rawApplication = json['application'];
    final source = rawApplication is Map
        ? {...json, ...Map<String, dynamic>.from(rawApplication)}
        : json;
    return LandlordTerminationDetail(
      item: LandlordTerminationItem.fromJson(source),
      reason: _string(source['reason']),
      actualMoveOutDate: _string(source['actualMoveOutDate']),
      refundAmount: _int(source['refundAmount']),
      deductionAmount: _int(source['deductionAmount']),
    );
  }
}

class RescissionSignResult {
  const RescissionSignResult({
    required this.action,
    required this.signUrl,
    required this.status,
    required this.currentUserSigned,
    required this.completed,
  });

  final String action;
  final String signUrl;
  final String status;
  final bool currentUserSigned;
  final bool completed;
  bool get isAuthorization => action == 'authorize';

  factory RescissionSignResult.fromJson(Map<String, dynamic> json) =>
      RescissionSignResult(
        action: _string(json['action']),
        signUrl: _string(json['signUrl'] ?? json['url'] ?? json['shortUrl']),
        status: _string(json['status']),
        currentUserSigned: _bool(
          json['currentUserSigned'] ?? json['lessorSigned'],
        ),
        completed:
            _bool(json['completed']) ||
            _string(json['status']).toLowerCase() == 'rescission_completed' ||
            _string(json['status']).toLowerCase() == 'completed',
      );
}

class LandlordContractDetail {
  const LandlordContractDetail({
    required this.orderId,
    required this.contractId,
    required this.contractStatus,
    required this.tenantSigned,
    required this.lessorSigned,
    required this.signStage,
    required this.orderStatus,
    required this.contract,
  });

  final String orderId;
  final String contractId;
  final String contractStatus;
  final bool tenantSigned;
  final bool lessorSigned;
  final String signStage;
  final String orderStatus;
  final ContractPreview contract;

  bool get canSign {
    final status = contractStatus.toLowerCase();
    final order = orderStatus.toLowerCase();
    final stage = signStage.toLowerCase();
    final waitingForLandlord =
        order == 'pendinglandlordsign' ||
        order == 'pending_landlord_sign' ||
        // 兼容旧版详情接口尚未返回 orderStatus，但明确标记当前签署人是房东。
        (order.isEmpty &&
            (stage == 'waiting_my_signature' ||
                stage == 'waiting_lessor_signature' ||
                stage == 'lessor'));
    return waitingForLandlord &&
        !lessorSigned &&
        status != 'signed' &&
        status != 'completed' &&
        status != 'cancelled' &&
        status != 'canceled' &&
        status != 'expired';
  }

  bool get wasRejected {
    final order = orderStatus.toLowerCase();
    return order == 'refundpending' || order == 'refund_pending';
  }

  String get operationStatusLabel {
    return switch (orderStatus.toLowerCase()) {
      'refundpending' || 'refund_pending' => '已拒签/退款处理中',
      'refunded' => '已拒签/退款成功',
      'refundfailed' || 'refund_failed' => '已拒签/退款异常',
      'completed' => '租约已生成',
      'cancelled' || 'canceled' => '合同已取消',
      _ => '',
    };
  }

  bool get unavailable {
    final status = contractStatus.toLowerCase();
    return status == 'cancelled' || status == 'canceled' || status == 'expired';
  }

  factory LandlordContractDetail.fromJson(Map<String, dynamic> json) {
    final contract = json['contract'];
    final order = json['order'];
    final rentOrder = json['rentOrder'];
    final orderMap = order is Map
        ? Map<String, dynamic>.from(order)
        : const <String, dynamic>{};
    final rentOrderMap = rentOrder is Map
        ? Map<String, dynamic>.from(rentOrder)
        : const <String, dynamic>{};
    final contractMap = contract is Map
        ? Map<String, dynamic>.from(contract)
        : const <String, dynamic>{};
    return LandlordContractDetail(
      orderId: _string(json['orderId']),
      contractId: _string(json['contractId']),
      contractStatus: _string(
        json['contractStatus'] ??
            contractMap['contractStatus'] ??
            contractMap['status'],
      ),
      tenantSigned: _bool(json['tenantSigned'] ?? contractMap['tenantSigned']),
      lessorSigned: _bool(json['lessorSigned'] ?? contractMap['lessorSigned']),
      signStage: _string(json['signStage'] ?? contractMap['signStage']),
      orderStatus: _string(
        json['orderStatus'] ??
            json['rentOrderStatus'] ??
            json['order_status'] ??
            orderMap['status'] ??
            rentOrderMap['status'],
      ),
      contract: ContractPreview.fromJson(contractMap),
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
