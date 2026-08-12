enum PaymentRecordStatus {
  pending,
  success,
  failed,
  refundPending,
  refundFailed,
  refunded;

  String get label => switch (this) {
    PaymentRecordStatus.pending => '待支付',
    PaymentRecordStatus.success => '支付成功',
    PaymentRecordStatus.failed => '支付失败',
    PaymentRecordStatus.refundPending => '退款处理中',
    PaymentRecordStatus.refundFailed => '退款异常',
    PaymentRecordStatus.refunded => '已退款',
  };

  static PaymentRecordStatus fromValue(Object? value) {
    final text = value?.toString();
    return PaymentRecordStatus.values.firstWhere(
      (status) => status.name == text,
      orElse: () => PaymentRecordStatus.pending,
    );
  }
}

enum PaymentRecordType {
  rent,
  deposit,
  serviceFee,
  refund;

  String get value => switch (this) {
    PaymentRecordType.rent => 'rent',
    PaymentRecordType.deposit => 'deposit',
    PaymentRecordType.serviceFee => 'service_fee',
    PaymentRecordType.refund => 'refund',
  };

  String get label => switch (this) {
    PaymentRecordType.rent => '租金',
    PaymentRecordType.deposit => '押金',
    PaymentRecordType.serviceFee => '服务费',
    PaymentRecordType.refund => '退款',
  };

  static PaymentRecordType? fromFilterValue(String? value) {
    if (value == null || value.isEmpty) return null;
    return PaymentRecordType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PaymentRecordType.rent,
    );
  }

  static PaymentRecordType fromValue(Object? value) {
    final text = value?.toString();
    return PaymentRecordType.values.firstWhere(
      (type) => type.value == text || type.name == text,
      orElse: () => PaymentRecordType.rent,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.paymentNo,
    required this.houseName,
    required this.type,
    required this.amount,
    required this.status,
    required this.paymentChannel,
    required this.channelTradeNo,
    required this.remark,
    required this.createdAt,
    this.orderId,
    this.leaseId,
    this.billId,
    this.paidAt,
  });

  final String id;
  final String paymentNo;
  final String houseName;
  final PaymentRecordType type;
  final int amount;
  final PaymentRecordStatus status;
  final String paymentChannel;
  final String channelTradeNo;
  final String remark;
  final DateTime createdAt;
  final String? orderId;
  final String? leaseId;
  final String? billId;
  final DateTime? paidAt;

  String get typeText => type.label;
  String get statusText => status.label;
  String get channelText {
    return switch (paymentChannel) {
      'wechat' || 'wx' => '微信支付',
      'alipay' => '支付宝',
      'mock' => '模拟支付',
      '' => '--',
      _ => paymentChannel,
    };
  }
}

class PaymentRecordPageResult {
  const PaymentRecordPageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.total,
  });

  final List<PaymentRecord> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int total;
}
