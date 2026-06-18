import '../domain/rental_flow_models.dart';
import 'rental_flow_service.dart';

/// 租房流程仓储，封装服务层业务调用。
class RentalFlowRepository {
  const RentalFlowRepository({required RentalFlowService service})
    : _service = service;

  final RentalFlowService _service;

  /// 获取租房流程详情。
  Future<RentalFlowState> getFlowDetail(String houseId) {
    return _service.getRentalFlowDetail(houseId: houseId);
  }

  /// 创建咨询。
  Future<void> consultHouse({required String houseId}) {
    return _service.createConsultation(houseId: houseId);
  }

  /// 预约看房。
  Future<ViewingAppointment> bookViewing({
    required String houseId,
    required String houseTitle,
    required ViewingType viewingType,
    required DateTime appointmentDate,
    required String appointmentTimeRange,
    required String contactName,
    required String contactPhone,
    String? remark,
  }) {
    return _service.createViewingAppointment(
      houseId: houseId,
      houseTitle: houseTitle,
      viewingType: viewingType,
      appointmentDate: appointmentDate,
      appointmentTimeRange: appointmentTimeRange,
      contactName: contactName,
      contactPhone: contactPhone,
      remark: remark,
    );
  }

  /// 确认管家或房东已确认预约。
  Future<ViewingAppointment> confirmViewingAppointment({
    required ViewingAppointment appointment,
  }) {
    return _service.confirmViewingAppointment(appointment: appointment);
  }

  /// 确认看房完成。
  Future<ViewingAppointment> completeViewing({
    required ViewingAppointment appointment,
  }) {
    return _service.completeViewing(appointment: appointment);
  }

  /// 确认租房意向。
  Future<void> confirmIntention({required String houseId}) {
    return _service.confirmRentalIntention(houseId: houseId);
  }

  /// 提交租房申请。
  Future<RentalApplication> submitApplication({
    required String houseId,
    required String tenantName,
    required String tenantPhone,
    required DateTime moveInDate,
    required int leaseMonths,
    required String paymentCycle,
    required bool hasPet,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) {
    return _service.submitRentalApplication(
      houseId: houseId,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      moveInDate: moveInDate,
      leaseMonths: leaseMonths,
      paymentCycle: paymentCycle,
      hasPet: hasPet,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );
  }

  /// 实名认证。
  Future<RealNameVerification> verifyRealName({
    required String realName,
    required String idCardNumber,
  }) {
    return _service.verifyRealName(
      realName: realName,
      idCardNumber: idCardNumber,
    );
  }

  /// 生成租约草稿。
  Future<LeaseContract> generateLeaseDraft({
    required String houseId,
    required RentalApplication application,
  }) {
    return _service.generateLeaseDraft(
      houseId: houseId,
      application: application,
    );
  }

  /// 确认合同。
  Future<LeaseContract> confirmContract({required LeaseContract contract}) {
    return _service.confirmContract(contract: contract);
  }

  /// 签署合同。
  Future<LeaseContract> signContract({required LeaseContract contract}) {
    return _service.signContract(contract: contract);
  }

  /// 支付订单。
  Future<RentalPayment> payOrder({required RentalPayment payment}) {
    return _service.payRentalOrder(payment: payment);
  }

  /// 创建支付订单。
  Future<RentalPayment> createPaymentOrder({required LeaseContract contract}) {
    return _service.createPaymentOrder(contract: contract);
  }

  /// 激活租约。
  Future<void> activateLease({required String contractId}) {
    return _service.activateLease(contractId: contractId);
  }

  /// 分配门锁权限。
  Future<LockPermission> grantLockPermission({
    required String houseId,
    required LeaseContract contract,
  }) {
    return _service.grantLockPermission(houseId: houseId, contract: contract);
  }

  /// 完成入住。
  Future<void> completeMoveIn({required String houseId}) {
    return _service.completeMoveIn(houseId: houseId);
  }
}
