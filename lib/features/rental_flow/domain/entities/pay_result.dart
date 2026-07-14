class PayResult {
  const PayResult({
    required this.orderId,
    required this.paymentRecordId,
    this.payType,
    this.paymentUrl,
    required this.orderStatus,
    required this.paymentNo,
    required this.amount,
  });

  final String orderId;
  final String paymentRecordId;
  final String? payType;
  final String? paymentUrl;
  final String orderStatus;
  final String paymentNo;
  final int amount;

  /// 是否需要打开 WebView 进行 H5 支付
  bool get needWebView => payType == 'h5' && paymentUrl != null;
}
