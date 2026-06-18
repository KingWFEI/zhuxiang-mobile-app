import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rental_flow_repository.dart';
import '../domain/rental_flow_models.dart';
import '../domain/rental_flow_status.dart';

/// 租房流程控制器，负责状态流转和异常处理。
class RentalFlowNotifier extends StateNotifier<RentalFlowState> {
  RentalFlowNotifier({required RentalFlowRepository repository})
    : _repository = repository,
      super(RentalFlowState.initial());

  final RentalFlowRepository _repository;

  /// 加载指定房源的租房流程状态。
  Future<void> loadFlow(String houseId) async {
    if (state.isLoading) return;
    state = state.copyWith(houseId: houseId, isLoading: true, clearError: true);
    try {
      state = (await _repository.getFlowDetail(
        houseId,
      )).copyWith(isLoading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  /// 发起房源咨询。
  Future<bool> startConsultation() async {
    return _run(
      expected: RentalFlowStatus.browsing,
      next: () async {
        await _repository.consultHouse(houseId: state.houseId);
        state = state.copyWith(status: RentalFlowStatus.consulted);
      },
    );
  }

  /// 预约看房。
  Future<bool> bookViewing({
    required String houseTitle,
    required ViewingType viewingType,
    required DateTime appointmentDate,
    required String appointmentTimeRange,
    required String contactName,
    required String contactPhone,
    String? remark,
  }) async {
    return _run(
      minimum: RentalFlowStatus.browsing,
      next: () async {
        final appointment = await _repository.bookViewing(
          houseId: state.houseId,
          houseTitle: houseTitle,
          viewingType: viewingType,
          appointmentDate: appointmentDate,
          appointmentTimeRange: appointmentTimeRange,
          contactName: contactName,
          contactPhone: contactPhone,
          remark: remark,
        );
        state = state.copyWith(
          status: RentalFlowStatus.appointmentPending,
          appointment: appointment,
        );
      },
    );
  }

  /// 模拟管家或房东确认预约。
  Future<bool> simulateLandlordConfirm() async {
    return _run(
      expected: RentalFlowStatus.appointmentPending,
      next: () async {
        final appointment = state.appointment;
        if (appointment == null) throw StateError('请先提交看房预约');
        final confirmed = await _repository.confirmViewingAppointment(
          appointment: appointment,
        );
        state = state.copyWith(
          status: RentalFlowStatus.appointmentConfirmed,
          appointment: confirmed,
        );
      },
    );
  }

  /// 完成看房。
  Future<bool> completeViewing() async {
    return _run(
      expected: RentalFlowStatus.appointmentConfirmed,
      next: () async {
        final appointment = state.appointment;
        if (appointment == null) throw StateError('请先完成预约确认');
        final completed = await _repository.completeViewing(
          appointment: appointment,
        );
        state = state.copyWith(
          status: RentalFlowStatus.viewingCompleted,
          appointment: completed,
        );
      },
    );
  }

  /// 确认租房意向。
  Future<bool> confirmIntention() async {
    return _run(
      expected: RentalFlowStatus.viewingCompleted,
      next: () async {
        await _repository.confirmIntention(houseId: state.houseId);
        state = state.copyWith(status: RentalFlowStatus.intentionConfirmed);
      },
    );
  }

  /// 提交租房申请。
  Future<bool> submitApplication({
    required String tenantName,
    required String tenantPhone,
    required DateTime moveInDate,
    required int leaseMonths,
    required String paymentCycle,
    required bool hasPet,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    return _run(
      minimum: RentalFlowStatus.browsing,
      next: () async {
        if (!state.status.isAtLeast(RentalFlowStatus.intentionConfirmed)) {
          await _repository.confirmIntention(houseId: state.houseId);
        }
        final application = await _repository.submitApplication(
          houseId: state.houseId,
          tenantName: tenantName,
          tenantPhone: tenantPhone,
          moveInDate: moveInDate,
          leaseMonths: leaseMonths,
          paymentCycle: paymentCycle,
          hasPet: hasPet,
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: emergencyContactPhone,
        );
        state = state.copyWith(
          status: RentalFlowStatus.applicationSubmitted,
          application: application,
        );
      },
    );
  }

  /// 完成实名认证。
  Future<bool> verifyRealName({
    required String realName,
    required String idCardNumber,
  }) async {
    return _run(
      expected: RentalFlowStatus.applicationSubmitted,
      next: () async {
        final verification = await _repository.verifyRealName(
          realName: realName,
          idCardNumber: idCardNumber,
        );
        state = state.copyWith(
          status: RentalFlowStatus.realNameVerified,
          verification: verification,
        );
      },
    );
  }

  /// 生成租约草稿。
  Future<bool> generateLeaseDraft() async {
    return _run(
      expected: RentalFlowStatus.realNameVerified,
      next: () async {
        final application = state.application;
        if (application == null) throw StateError('请先提交租房申请');
        final contract = await _repository.generateLeaseDraft(
          houseId: state.houseId,
          application: application,
        );
        state = state.copyWith(
          status: RentalFlowStatus.leaseDraftGenerated,
          contract: contract,
        );
      },
    );
  }

  /// 确认合同内容。
  Future<bool> confirmContract() async {
    return _run(
      expected: RentalFlowStatus.leaseDraftGenerated,
      next: () async {
        final contract = state.contract;
        if (contract == null) throw StateError('请先生成租约草稿');
        final confirmed = await _repository.confirmContract(contract: contract);
        state = state.copyWith(
          status: RentalFlowStatus.contractConfirmed,
          contract: confirmed,
        );
      },
    );
  }

  /// 在线签署合同。
  Future<bool> signContract() async {
    return _run(
      expected: RentalFlowStatus.contractConfirmed,
      next: () async {
        final contract = state.contract;
        if (contract == null) throw StateError('请先确认合同');
        final signed = await _repository.signContract(contract: contract);
        state = state.copyWith(
          status: RentalFlowStatus.contractSigned,
          contract: signed,
        );
      },
    );
  }

  /// 创建支付订单。
  Future<bool> createPaymentOrder() async {
    return _run(
      expected: RentalFlowStatus.contractSigned,
      next: () async {
        final contract = state.contract;
        if (contract == null) throw StateError('请先签署合同');
        final payment = await _repository.createPaymentOrder(
          contract: contract,
        );
        state = state.copyWith(
          status: RentalFlowStatus.paymentPending,
          payment: payment,
        );
      },
    );
  }

  /// 支付押金和首期租金。
  Future<bool> payOrder() async {
    return _run(
      expected: RentalFlowStatus.paymentPending,
      next: () async {
        final payment = state.payment;
        if (payment == null) throw StateError('请先创建支付订单');
        final paid = await _repository.payOrder(payment: payment);
        state = state.copyWith(status: RentalFlowStatus.paid, payment: paid);
      },
    );
  }

  /// 激活租约。
  Future<bool> activateLease() async {
    return _run(
      expected: RentalFlowStatus.paid,
      next: () async {
        final contract = state.contract;
        if (contract == null) throw StateError('请先签署合同');
        await _repository.activateLease(contractId: contract.id);
        state = state.copyWith(status: RentalFlowStatus.leaseActive);
      },
    );
  }

  /// 分配门锁权限。
  Future<bool> grantLockPermission() async {
    return _run(
      expected: RentalFlowStatus.leaseActive,
      next: () async {
        final contract = state.contract;
        if (contract == null) throw StateError('请先激活租约');
        final permission = await _repository.grantLockPermission(
          houseId: state.houseId,
          contract: contract,
        );
        state = state.copyWith(
          status: RentalFlowStatus.lockPermissionGranted,
          lockPermission: permission,
        );
      },
    );
  }

  /// 完成入住。
  Future<bool> completeMoveIn() async {
    return _run(
      expected: RentalFlowStatus.lockPermissionGranted,
      next: () async {
        await _repository.completeMoveIn(houseId: state.houseId);
        state = state.copyWith(status: RentalFlowStatus.moveInCompleted);
      },
    );
  }

  Future<bool> _run({
    RentalFlowStatus? expected,
    RentalFlowStatus? minimum,
    required Future<void> Function() next,
  }) async {
    if (state.isLoading) return false;
    if (expected != null && state.status != expected) {
      state = state.copyWith(
        errorMessage: '当前状态为「${state.status.label}」，请先完成前置步骤',
      );
      return false;
    }
    if (minimum != null && !state.status.isAtLeast(minimum)) {
      state = state.copyWith(
        errorMessage: '当前状态为「${state.status.label}」，暂不能执行该操作',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await next();
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
  }
}
