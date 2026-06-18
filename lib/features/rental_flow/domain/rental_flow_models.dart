import 'rental_flow_status.dart';

enum ViewingType { offline, online }

enum AppointmentStatus { pending, confirmed, completed, cancelled }

enum RentalApplicationStatus { submitted, approved, rejected, needMoreInfo }

enum VerificationStatus { unverified, verified, failed }

enum ContractStatus { draft, confirmed, signed }

enum PaymentStatus { pending, paid, failed }

enum LockPermissionStatus { active, expired, disabled }

T _enumFromJson<T extends Enum>(List<T> values, String? value, T fallback) {
  return values.firstWhere(
    (item) => item.name == value,
    orElse: () => fallback,
  );
}

/// 看房预约信息。
class ViewingAppointment {
  const ViewingAppointment({
    required this.id,
    required this.houseId,
    required this.houseTitle,
    required this.viewingType,
    required this.appointmentDate,
    required this.appointmentTimeRange,
    required this.contactName,
    required this.contactPhone,
    required this.remark,
    required this.status,
  });

  final String id;
  final String houseId;
  final String houseTitle;
  final ViewingType viewingType;
  final DateTime appointmentDate;
  final String appointmentTimeRange;
  final String contactName;
  final String contactPhone;
  final String remark;
  final AppointmentStatus status;

  ViewingAppointment copyWith({AppointmentStatus? status}) {
    return ViewingAppointment(
      id: id,
      houseId: houseId,
      houseTitle: houseTitle,
      viewingType: viewingType,
      appointmentDate: appointmentDate,
      appointmentTimeRange: appointmentTimeRange,
      contactName: contactName,
      contactPhone: contactPhone,
      remark: remark,
      status: status ?? this.status,
    );
  }

  factory ViewingAppointment.fromJson(Map<String, dynamic> json) {
    return ViewingAppointment(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      houseTitle: json['houseTitle'] as String? ?? '',
      viewingType: _enumFromJson(
        ViewingType.values,
        json['viewingType'] as String?,
        ViewingType.offline,
      ),
      appointmentDate:
          DateTime.tryParse(json['appointmentDate'] as String? ?? '') ??
          DateTime.now(),
      appointmentTimeRange: json['appointmentTimeRange'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      status: _enumFromJson(
        AppointmentStatus.values,
        json['status'] as String?,
        AppointmentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseId': houseId,
      'houseTitle': houseTitle,
      'viewingType': viewingType.name,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTimeRange': appointmentTimeRange,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'remark': remark,
      'status': status.name,
    };
  }
}

/// 租房申请信息。
class RentalApplication {
  const RentalApplication({
    required this.id,
    required this.houseId,
    required this.tenantName,
    required this.tenantPhone,
    required this.moveInDate,
    required this.leaseMonths,
    required this.paymentCycle,
    required this.hasPet,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.status,
  });

  final String id;
  final String houseId;
  final String tenantName;
  final String tenantPhone;
  final DateTime moveInDate;
  final int leaseMonths;
  final String paymentCycle;
  final bool hasPet;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final RentalApplicationStatus status;

  factory RentalApplication.fromJson(Map<String, dynamic> json) {
    return RentalApplication(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '',
      tenantPhone: json['tenantPhone'] as String? ?? '',
      moveInDate:
          DateTime.tryParse(json['moveInDate'] as String? ?? '') ??
          DateTime.now(),
      leaseMonths: (json['leaseMonths'] as num?)?.toInt() ?? 12,
      paymentCycle: json['paymentCycle'] as String? ?? '',
      hasPet: json['hasPet'] as bool? ?? false,
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
      status: _enumFromJson(
        RentalApplicationStatus.values,
        json['status'] as String?,
        RentalApplicationStatus.submitted,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseId': houseId,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'moveInDate': moveInDate.toIso8601String(),
      'leaseMonths': leaseMonths,
      'paymentCycle': paymentCycle,
      'hasPet': hasPet,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'status': status.name,
    };
  }
}

/// 实名认证信息。
class RealNameVerification {
  const RealNameVerification({
    required this.id,
    required this.realName,
    required this.idCardNumber,
    required this.status,
  });

  final String id;
  final String realName;
  final String idCardNumber;
  final VerificationStatus status;

  factory RealNameVerification.fromJson(Map<String, dynamic> json) {
    return RealNameVerification(
      id: json['id'] as String? ?? '',
      realName: json['realName'] as String? ?? '',
      idCardNumber: json['idCardNumber'] as String? ?? '',
      status: _enumFromJson(
        VerificationStatus.values,
        json['status'] as String?,
        VerificationStatus.unverified,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'realName': realName,
      'idCardNumber': idCardNumber,
      'status': status.name,
    };
  }
}

/// 租约合同信息。
class LeaseContract {
  const LeaseContract({
    required this.id,
    required this.houseId,
    required this.tenantName,
    required this.rentAmount,
    required this.depositAmount,
    required this.serviceFee,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.paymentCycle,
    required this.contractStatus,
  });

  final String id;
  final String houseId;
  final String tenantName;
  final int rentAmount;
  final int depositAmount;
  final int serviceFee;
  final DateTime leaseStartDate;
  final DateTime leaseEndDate;
  final String paymentCycle;
  final ContractStatus contractStatus;

  LeaseContract copyWith({ContractStatus? contractStatus}) {
    return LeaseContract(
      id: id,
      houseId: houseId,
      tenantName: tenantName,
      rentAmount: rentAmount,
      depositAmount: depositAmount,
      serviceFee: serviceFee,
      leaseStartDate: leaseStartDate,
      leaseEndDate: leaseEndDate,
      paymentCycle: paymentCycle,
      contractStatus: contractStatus ?? this.contractStatus,
    );
  }

  factory LeaseContract.fromJson(Map<String, dynamic> json) {
    return LeaseContract(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '',
      rentAmount: (json['rentAmount'] as num?)?.toInt() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toInt() ?? 0,
      serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 0,
      leaseStartDate:
          DateTime.tryParse(json['leaseStartDate'] as String? ?? '') ??
          DateTime.now(),
      leaseEndDate:
          DateTime.tryParse(json['leaseEndDate'] as String? ?? '') ??
          DateTime.now(),
      paymentCycle: json['paymentCycle'] as String? ?? '',
      contractStatus: _enumFromJson(
        ContractStatus.values,
        json['contractStatus'] as String?,
        ContractStatus.draft,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseId': houseId,
      'tenantName': tenantName,
      'rentAmount': rentAmount,
      'depositAmount': depositAmount,
      'serviceFee': serviceFee,
      'leaseStartDate': leaseStartDate.toIso8601String(),
      'leaseEndDate': leaseEndDate.toIso8601String(),
      'paymentCycle': paymentCycle,
      'contractStatus': contractStatus.name,
    };
  }
}

/// 租房支付订单。
class RentalPayment {
  const RentalPayment({
    required this.id,
    required this.contractId,
    required this.depositAmount,
    required this.firstRentAmount,
    required this.serviceFee,
    required this.totalAmount,
    required this.paymentStatus,
  });

  final String id;
  final String contractId;
  final int depositAmount;
  final int firstRentAmount;
  final int serviceFee;
  final int totalAmount;
  final PaymentStatus paymentStatus;

  RentalPayment copyWith({PaymentStatus? paymentStatus}) {
    return RentalPayment(
      id: id,
      contractId: contractId,
      depositAmount: depositAmount,
      firstRentAmount: firstRentAmount,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  factory RentalPayment.fromJson(Map<String, dynamic> json) {
    return RentalPayment(
      id: json['id'] as String? ?? '',
      contractId: json['contractId'] as String? ?? '',
      depositAmount: (json['depositAmount'] as num?)?.toInt() ?? 0,
      firstRentAmount: (json['firstRentAmount'] as num?)?.toInt() ?? 0,
      serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      paymentStatus: _enumFromJson(
        PaymentStatus.values,
        json['paymentStatus'] as String?,
        PaymentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'depositAmount': depositAmount,
      'firstRentAmount': firstRentAmount,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus.name,
    };
  }
}

/// 智能门锁权限。
class LockPermission {
  const LockPermission({
    required this.id,
    required this.houseId,
    required this.tenantId,
    required this.lockId,
    required this.permissionStartTime,
    required this.permissionEndTime,
    required this.bluetoothEnabled,
    required this.remoteUnlockEnabled,
    required this.status,
  });

  final String id;
  final String houseId;
  final String tenantId;
  final String lockId;
  final DateTime permissionStartTime;
  final DateTime permissionEndTime;
  final bool bluetoothEnabled;
  final bool remoteUnlockEnabled;
  final LockPermissionStatus status;

  factory LockPermission.fromJson(Map<String, dynamic> json) {
    return LockPermission(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      lockId: json['lockId'] as String? ?? '',
      permissionStartTime:
          DateTime.tryParse(json['permissionStartTime'] as String? ?? '') ??
          DateTime.now(),
      permissionEndTime:
          DateTime.tryParse(json['permissionEndTime'] as String? ?? '') ??
          DateTime.now(),
      bluetoothEnabled: json['bluetoothEnabled'] as bool? ?? false,
      remoteUnlockEnabled: json['remoteUnlockEnabled'] as bool? ?? false,
      status: _enumFromJson(
        LockPermissionStatus.values,
        json['status'] as String?,
        LockPermissionStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseId': houseId,
      'tenantId': tenantId,
      'lockId': lockId,
      'permissionStartTime': permissionStartTime.toIso8601String(),
      'permissionEndTime': permissionEndTime.toIso8601String(),
      'bluetoothEnabled': bluetoothEnabled,
      'remoteUnlockEnabled': remoteUnlockEnabled,
      'status': status.name,
    };
  }
}

/// 租房流程状态。
class RentalFlowState {
  const RentalFlowState({
    required this.houseId,
    required this.status,
    required this.appointment,
    required this.application,
    required this.verification,
    required this.contract,
    required this.payment,
    required this.lockPermission,
    required this.isLoading,
    required this.errorMessage,
  });

  factory RentalFlowState.initial({String houseId = ''}) {
    return RentalFlowState(
      houseId: houseId,
      status: RentalFlowStatus.browsing,
      appointment: null,
      application: null,
      verification: null,
      contract: null,
      payment: null,
      lockPermission: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  final String houseId;
  final RentalFlowStatus status;
  final ViewingAppointment? appointment;
  final RentalApplication? application;
  final RealNameVerification? verification;
  final LeaseContract? contract;
  final RentalPayment? payment;
  final LockPermission? lockPermission;
  final bool isLoading;
  final String? errorMessage;

  RentalFlowState copyWith({
    String? houseId,
    RentalFlowStatus? status,
    ViewingAppointment? appointment,
    RentalApplication? application,
    RealNameVerification? verification,
    LeaseContract? contract,
    RentalPayment? payment,
    LockPermission? lockPermission,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RentalFlowState(
      houseId: houseId ?? this.houseId,
      status: status ?? this.status,
      appointment: appointment ?? this.appointment,
      application: application ?? this.application,
      verification: verification ?? this.verification,
      contract: contract ?? this.contract,
      payment: payment ?? this.payment,
      lockPermission: lockPermission ?? this.lockPermission,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
