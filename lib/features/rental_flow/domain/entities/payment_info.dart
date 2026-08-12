class PaymentInfo {
  const PaymentInfo({
    required this.orderId,
    required this.amount,
    required this.monthlyRent,
    required this.paymentMonths,
    required this.deposit,
    required this.serviceFee,
    required this.paymentMethods,
    this.selectedPaymentMethod,
    this.payType,
    this.paymentUrl,
  });

  final String orderId;
  final int amount;
  final int monthlyRent;
  final int paymentMonths;
  final int deposit;
  final int serviceFee;
  final List<String> paymentMethods;
  final String? selectedPaymentMethod;
  final String? payType;
  final String? paymentUrl;

  PaymentInfo copyWith({String? selectedPaymentMethod}) {
    return PaymentInfo(
      orderId: orderId,
      amount: amount,
      monthlyRent: monthlyRent,
      paymentMonths: paymentMonths,
      deposit: deposit,
      serviceFee: serviceFee,
      paymentMethods: paymentMethods,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      payType: payType,
      paymentUrl: paymentUrl,
    );
  }
}
