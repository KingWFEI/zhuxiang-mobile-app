/// 租房流程主状态。
enum RentalFlowStatus {
  browsing,
  consulted,
  appointmentPending,
  appointmentConfirmed,
  viewingCompleted,
  intentionConfirmed,
  applicationSubmitted,
  realNameVerified,
  leaseDraftGenerated,
  contractConfirmed,
  contractSigned,
  paymentPending,
  paid,
  leaseActive,
  lockPermissionGranted,
  moveInCompleted,
}

/// 租房流程状态展示与流转扩展。
extension RentalFlowStatusX on RentalFlowStatus {
  static const ordered = [
    RentalFlowStatus.browsing,
    RentalFlowStatus.consulted,
    RentalFlowStatus.appointmentPending,
    RentalFlowStatus.appointmentConfirmed,
    RentalFlowStatus.viewingCompleted,
    RentalFlowStatus.intentionConfirmed,
    RentalFlowStatus.applicationSubmitted,
    RentalFlowStatus.realNameVerified,
    RentalFlowStatus.leaseDraftGenerated,
    RentalFlowStatus.contractConfirmed,
    RentalFlowStatus.contractSigned,
    RentalFlowStatus.paymentPending,
    RentalFlowStatus.paid,
    RentalFlowStatus.leaseActive,
    RentalFlowStatus.lockPermissionGranted,
    RentalFlowStatus.moveInCompleted,
  ];

  String get label {
    return switch (this) {
      RentalFlowStatus.browsing => '浏览房源',
      RentalFlowStatus.consulted => '已咨询',
      RentalFlowStatus.appointmentPending => '预约待确认',
      RentalFlowStatus.appointmentConfirmed => '预约已确认',
      RentalFlowStatus.viewingCompleted => '已看房',
      RentalFlowStatus.intentionConfirmed => '已确认意向',
      RentalFlowStatus.applicationSubmitted => '申请已提交',
      RentalFlowStatus.realNameVerified => '实名已认证',
      RentalFlowStatus.leaseDraftGenerated => '租约草稿已生成',
      RentalFlowStatus.contractConfirmed => '合同已确认',
      RentalFlowStatus.contractSigned => '合同已签约',
      RentalFlowStatus.paymentPending => '待支付',
      RentalFlowStatus.paid => '已支付',
      RentalFlowStatus.leaseActive => '租约生效',
      RentalFlowStatus.lockPermissionGranted => '门锁已授权',
      RentalFlowStatus.moveInCompleted => '入住完成',
    };
  }

  int get order => ordered.indexOf(this);

  bool isAtLeast(RentalFlowStatus status) => order >= status.order;
}

RentalFlowStatus rentalFlowStatusFromJson(String? value) {
  return RentalFlowStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => RentalFlowStatus.browsing,
  );
}
