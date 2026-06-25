enum RentalFlowStep {
  realName('实名认证'),
  contract('合同预览'),
  payment('支付'),
  onlineSign('在线签约'),
  success('租住成功');

  const RentalFlowStep(this.label);

  final String label;
}
