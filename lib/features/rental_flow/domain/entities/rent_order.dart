enum RentOrderStatus {
  created,
  pendingRealName,
  pendingContract,
  pendingPayment,
  pendingSign,
  pendingLandlordSign,
  completed,
  cancelled;

  String get label {
    return switch (this) {
      RentOrderStatus.created => '已创建',
      RentOrderStatus.pendingRealName => '待实名',
      RentOrderStatus.pendingContract => '待确认合同',
      RentOrderStatus.pendingPayment => '待支付',
      RentOrderStatus.pendingSign => '待签约',
      RentOrderStatus.pendingLandlordSign => '待房东签约',
      RentOrderStatus.completed => '已完成',
      RentOrderStatus.cancelled => '已取消',
    };
  }
}

class RentOrder {
  const RentOrder({
    required this.id,
    required this.orderNo,
    required this.houseId,
    required this.houseName,
    required this.roomName,
    required this.address,
    required this.coverUrl,
    required this.startDate,
    required this.leaseMonths,
    required this.paymentMethod,
    required this.tenantCount,
    required this.monthlyRent,
    required this.deposit,
    required this.serviceFee,
    required this.firstPaymentAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.paymentDeadline,
    this.prePaymentDeadline,
  });

  final String id;
  final String orderNo;
  final String houseId;
  final String houseName;
  final String roomName;
  final String address;
  final String coverUrl;
  final DateTime startDate;
  final int leaseMonths;
  final String paymentMethod;
  final int tenantCount;
  final int monthlyRent;
  final int deposit;
  final int serviceFee;
  final int firstPaymentAmount;
  final RentOrderStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paymentDeadline;
  final DateTime? prePaymentDeadline;

  DateTime get endDate => DateTime(
    startDate.year,
    startDate.month + leaseMonths,
    startDate.day,
  ).subtract(const Duration(days: 1));

  RentOrder copyWith({RentOrderStatus? status}) {
    return RentOrder(
      id: id,
      orderNo: orderNo,
      houseId: houseId,
      houseName: houseName,
      roomName: roomName,
      address: address,
      coverUrl: coverUrl,
      startDate: startDate,
      leaseMonths: leaseMonths,
      paymentMethod: paymentMethod,
      tenantCount: tenantCount,
      monthlyRent: monthlyRent,
      deposit: deposit,
      serviceFee: serviceFee,
      firstPaymentAmount: firstPaymentAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentDeadline: paymentDeadline,
      prePaymentDeadline: prePaymentDeadline,
    );
  }
}
