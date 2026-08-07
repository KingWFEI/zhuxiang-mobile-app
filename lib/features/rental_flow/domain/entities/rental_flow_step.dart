enum RentalFlowStep {
  realName('实名认证'),
  contract('合同预览'),
  onlineSign('在线签约'),
  payment('支付'),
  success('租住成功');

  const RentalFlowStep(this.label);

  final String label;
}
