import '../../../core/network/api_client.dart';
import '../domain/rental_flow_models.dart';

/// 租房流程服务，当前使用模拟数据，后续可替换为真实接口。
class RentalFlowService {
  RentalFlowService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  ApiClient get apiClient => _apiClient;

  /// 创建咨询会话。
  Future<void> createConsultation({required String houseId}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // await apiClient.post('/rental-flow/$houseId/consultations');
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// 提交预约看房申请。
  Future<ViewingAppointment> createViewingAppointment({
    required String houseId,
    required String houseTitle,
    required ViewingType viewingType,
    required DateTime appointmentDate,
    required String appointmentTimeRange,
    required String contactName,
    required String contactPhone,
    String? remark,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/appointments', data: {...});
    await Future.delayed(const Duration(milliseconds: 500));
    return ViewingAppointment(
      id: 'appointment_${DateTime.now().millisecondsSinceEpoch}',
      houseId: houseId,
      houseTitle: houseTitle,
      viewingType: viewingType,
      appointmentDate: appointmentDate,
      appointmentTimeRange: appointmentTimeRange,
      contactName: contactName,
      contactPhone: contactPhone,
      remark: remark ?? '',
      status: AppointmentStatus.pending,
    );
  }

  /// 模拟管家或房东确认看房预约。
  Future<ViewingAppointment> confirmViewingAppointment({
    required ViewingAppointment appointment,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/appointments/${appointment.id}/confirm');
    await Future.delayed(const Duration(milliseconds: 450));
    return appointment.copyWith(status: AppointmentStatus.confirmed);
  }

  /// 标记用户已完成看房。
  Future<ViewingAppointment> completeViewing({
    required ViewingAppointment appointment,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/appointments/${appointment.id}/complete');
    await Future.delayed(const Duration(milliseconds: 450));
    return appointment.copyWith(status: AppointmentStatus.completed);
  }

  /// 用户确认租房意向。
  Future<void> confirmRentalIntention({required String houseId}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // await apiClient.post('/rental-flow/$houseId/intention');
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// 提交租房申请。
  Future<RentalApplication> submitRentalApplication({
    required String houseId,
    required String tenantName,
    required String tenantPhone,
    required DateTime moveInDate,
    required int leaseMonths,
    required String paymentCycle,
    required bool hasPet,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/applications', data: {...});
    await Future.delayed(const Duration(milliseconds: 600));
    return RentalApplication(
      id: 'application_${DateTime.now().millisecondsSinceEpoch}',
      houseId: houseId,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      moveInDate: moveInDate,
      leaseMonths: leaseMonths,
      paymentCycle: paymentCycle,
      hasPet: hasPet,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      status: RentalApplicationStatus.submitted,
    );
  }

  /// 提交实名认证信息。
  Future<RealNameVerification> verifyRealName({
    required String realName,
    required String idCardNumber,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/verification', data: {...});
    await Future.delayed(const Duration(milliseconds: 650));
    return RealNameVerification(
      id: 'verify_${DateTime.now().millisecondsSinceEpoch}',
      realName: realName,
      idCardNumber: idCardNumber,
      status: VerificationStatus.verified,
    );
  }

  /// 生成租约草稿。
  Future<LeaseContract> generateLeaseDraft({
    required String houseId,
    required RentalApplication application,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/contracts/draft', data: {...});
    await Future.delayed(const Duration(milliseconds: 600));
    final startDate = application.moveInDate;
    return LeaseContract(
      id: 'contract_${DateTime.now().millisecondsSinceEpoch}',
      houseId: houseId,
      tenantName: application.tenantName,
      rentAmount: 3200,
      depositAmount: 3200,
      serviceFee: 300,
      leaseStartDate: startDate,
      leaseEndDate: DateTime(
        startDate.year,
        startDate.month + application.leaseMonths,
        startDate.day,
      ),
      paymentCycle: application.paymentCycle,
      contractStatus: ContractStatus.draft,
    );
  }

  /// 确认合同信息。
  Future<LeaseContract> confirmContract({
    required LeaseContract contract,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/contracts/${contract.id}/confirm');
    await Future.delayed(const Duration(milliseconds: 450));
    return contract.copyWith(contractStatus: ContractStatus.confirmed);
  }

  /// 在线签署合同。
  Future<LeaseContract> signContract({required LeaseContract contract}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/contracts/${contract.id}/sign');
    await Future.delayed(const Duration(milliseconds: 500));
    return contract.copyWith(contractStatus: ContractStatus.signed);
  }

  /// 创建押金和首期租金支付订单。
  Future<RentalPayment> createPaymentOrder({
    required LeaseContract contract,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/payments', data: {...});
    await Future.delayed(const Duration(milliseconds: 450));
    final total =
        contract.depositAmount + contract.rentAmount + contract.serviceFee;
    return RentalPayment(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      contractId: contract.id,
      depositAmount: contract.depositAmount,
      firstRentAmount: contract.rentAmount,
      serviceFee: contract.serviceFee,
      totalAmount: total,
      paymentStatus: PaymentStatus.pending,
    );
  }

  /// 模拟支付租房订单。
  Future<RentalPayment> payRentalOrder({required RentalPayment payment}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/payments/${payment.id}/pay');
    await Future.delayed(const Duration(milliseconds: 700));
    return payment.copyWith(paymentStatus: PaymentStatus.paid);
  }

  /// 激活租约。
  Future<void> activateLease({required String contractId}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // await apiClient.post('/rental-flow/contracts/$contractId/activate');
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// 分配智能门锁权限。
  Future<LockPermission> grantLockPermission({
    required String houseId,
    required LeaseContract contract,
  }) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.post('/rental-flow/locks/grant', data: {...});
    await Future.delayed(const Duration(milliseconds: 500));
    return LockPermission(
      id: 'lock_permission_${DateTime.now().millisecondsSinceEpoch}',
      houseId: houseId,
      tenantId: 'tenant_mock_001',
      lockId: 'lock_$houseId',
      permissionStartTime: contract.leaseStartDate,
      permissionEndTime: contract.leaseEndDate,
      bluetoothEnabled: true,
      remoteUnlockEnabled: true,
      status: LockPermissionStatus.active,
    );
  }

  /// 完成入住流程。
  Future<void> completeMoveIn({required String houseId}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // await apiClient.post('/rental-flow/$houseId/move-in/complete');
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// 获取当前房源对应的租房流程详情。
  Future<RentalFlowState> getRentalFlowDetail({required String houseId}) async {
    // TODO: 当前为模拟数据，后续替换为真实后端接口
    // final result = await apiClient.get('/rental-flow/$houseId');
    await Future.delayed(const Duration(milliseconds: 350));
    return RentalFlowState.initial(houseId: houseId);
  }
}
