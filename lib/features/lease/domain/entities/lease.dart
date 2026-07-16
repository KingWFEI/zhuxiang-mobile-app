import 'package:flutter/material.dart';

enum LeaseStatus {
  active('履约中', Color(0xFF2E7D32)),
  pending('待生效', Color(0xFFF59E0B)),
  expired('已到期', Color(0xFF9CA3AF)),
  checkedOut('已退租', Color(0xFF7B8190)),
  cancelled('已取消', Color(0xFFD32F2F));

  const LeaseStatus(this.label, this.color);
  final String label;
  final Color color;
}

enum LeaseContractStatus {
  unsigned('待签约'),
  signed('已签约'),
  voided('已作废');

  const LeaseContractStatus(this.label);
  final String label;
}

enum LeaseBillStatus {
  normal('正常'),
  unpaid('待缴费'),
  overdue('已逾期'),
  paid('已结清');

  const LeaseBillStatus(this.label);
  final String label;
}

enum LeaseLockPermissionStatus {
  active('已授权'),
  expired('已过期'),
  revoked('已回收');

  const LeaseLockPermissionStatus(this.label);
  final String label;
}

class Lease {
  const Lease({
    required this.id,
    required this.contractId,
    required this.houseId,
    required this.houseName,
    required this.houseAddress,
    required this.houseSummary,
    required this.houseImageUrl,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantIdCard,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    required this.paymentMethod,
    required this.paymentDay,
    required this.status,
    required this.contractStatus,
    required this.billStatus,
    required this.lockPermissionStatus,
    required this.keeperName,
    required this.keeperPhone,
    required this.pendingBillTitle,
    required this.pendingBillAmount,
    required this.pendingBillDueDate,
  });

  final String id;
  final String contractId;
  final String houseId;
  final String houseName;
  final String houseAddress;
  final String houseSummary;
  final String houseImageUrl;
  final String tenantName;
  final String tenantPhone;
  final String tenantIdCard;
  final DateTime startDate;
  final DateTime endDate;
  final int monthlyRent;
  final int deposit;
  final String paymentMethod;
  final int paymentDay;
  final LeaseStatus status;
  final LeaseContractStatus contractStatus;
  final LeaseBillStatus billStatus;
  final LeaseLockPermissionStatus lockPermissionStatus;
  final String keeperName;
  final String keeperPhone;
  final String pendingBillTitle;
  final int pendingBillAmount;
  final DateTime pendingBillDueDate;

  bool get isCurrent =>
      status == LeaseStatus.active || status == LeaseStatus.pending;
  bool get canOperate => status == LeaseStatus.active;

  String get maskedTenantPhone {
    if (tenantPhone.length < 7) return tenantPhone;
    return '${tenantPhone.substring(0, 3)}****${tenantPhone.substring(tenantPhone.length - 4)}';
  }

  String get maskedIdCard {
    if (tenantIdCard.length < 8) return tenantIdCard;
    return '${tenantIdCard.substring(0, 4)}**********${tenantIdCard.substring(tenantIdCard.length - 4)}';
  }

  Lease copyWith({LeaseStatus? status}) {
    return Lease(
      id: id,
      contractId: contractId,
      houseId: houseId,
      houseName: houseName,
      houseAddress: houseAddress,
      houseSummary: houseSummary,
      houseImageUrl: houseImageUrl,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      tenantIdCard: tenantIdCard,
      startDate: startDate,
      endDate: endDate,
      monthlyRent: monthlyRent,
      deposit: deposit,
      paymentMethod: paymentMethod,
      paymentDay: paymentDay,
      status: status ?? this.status,
      contractStatus: contractStatus,
      billStatus: billStatus,
      lockPermissionStatus: lockPermissionStatus,
      keeperName: keeperName,
      keeperPhone: keeperPhone,
      pendingBillTitle: pendingBillTitle,
      pendingBillAmount: pendingBillAmount,
      pendingBillDueDate: pendingBillDueDate,
    );
  }
}
