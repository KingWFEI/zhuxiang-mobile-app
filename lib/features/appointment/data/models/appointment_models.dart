class ViewingSlot {
  const ViewingSlot({
    required this.startAt,
    required this.endAt,
    required this.available,
    this.accessValidFrom,
    this.accessValidTo,
    this.testSlot = false,
  });

  factory ViewingSlot.fromJson(Map<String, dynamic> json) {
    return ViewingSlot(
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      available: json['available'] as bool? ?? false,
      accessValidFrom: _date(json['accessValidFrom']),
      accessValidTo: _date(json['accessValidTo']),
      testSlot: json['testSlot'] as bool? ?? false,
    );
  }

  final DateTime startAt;
  final DateTime endAt;
  final bool available;
  final DateTime? accessValidFrom;
  final DateTime? accessValidTo;
  final bool testSlot;
}

class ViewingSlotDay {
  const ViewingSlotDay({required this.date, required this.slots});

  factory ViewingSlotDay.fromJson(Map<String, dynamic> json) {
    return ViewingSlotDay(
      date: DateTime.parse(json['date'] as String),
      slots: (json['slots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ViewingSlot.fromJson)
          .toList(growable: false),
    );
  }

  final DateTime date;
  final List<ViewingSlot> slots;
}

class ViewingSlotResult {
  const ViewingSlotResult({
    required this.houseId,
    required this.viewingMode,
    required this.requiresConfirmation,
    required this.dates,
  });

  factory ViewingSlotResult.fromJson(Map<String, dynamic> json) {
    return ViewingSlotResult(
      houseId: json['houseId'] as String? ?? '',
      viewingMode: json['viewingMode'] as String? ?? 'LANDLORD_HOSTED',
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
      dates: (json['dates'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ViewingSlotDay.fromJson)
          .toList(growable: false),
    );
  }

  final String houseId;
  final String viewingMode;
  final bool requiresConfirmation;
  final List<ViewingSlotDay> dates;
}

class AppointmentCreateResult {
  const AppointmentCreateResult({
    required this.id,
    required this.status,
    required this.viewingMode,
    required this.requiresConfirmation,
  });

  factory AppointmentCreateResult.fromJson(Map<String, dynamic> json) {
    return AppointmentCreateResult(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING_CONFIRMATION',
      viewingMode: json['viewingMode'] as String? ?? 'LANDLORD_HOSTED',
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
    );
  }

  final String id;
  final String status;
  final String viewingMode;
  final bool requiresConfirmation;
}

class AppointmentSummary {
  const AppointmentSummary({
    required this.id,
    required this.houseId,
    required this.houseTitle,
    required this.coverImage,
    required this.sourceType,
    required this.sourceLabel,
    required this.viewingMode,
    required this.viewingModeLabel,
    required this.status,
    required this.appointmentStartAt,
    required this.appointmentEndAt,
    required this.accessStatus,
    required this.availableActions,
  });

  factory AppointmentSummary.fromJson(Map<String, dynamic> json) {
    return AppointmentSummary(
      id: json['id'] as String? ?? '',
      houseId: json['houseId'] as String? ?? '',
      houseTitle: json['houseTitle'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'LANDLORD',
      sourceLabel: json['sourceLabel'] as String? ?? '个人房源',
      viewingMode: json['viewingMode'] as String? ?? 'LANDLORD_HOSTED',
      viewingModeLabel: json['viewingModeLabel'] as String? ?? '房东陪同',
      status: json['status'] as String? ?? 'PENDING_CONFIRMATION',
      appointmentStartAt: _date(json['appointmentStartAt']),
      appointmentEndAt: _date(json['appointmentEndAt']),
      accessStatus: json['accessStatus'] as String? ?? 'NOT_REQUIRED',
      availableActions: (json['availableActions'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final String id;
  final String houseId;
  final String houseTitle;
  final String coverImage;
  final String sourceType;
  final String sourceLabel;
  final String viewingMode;
  final String viewingModeLabel;
  final String status;
  final DateTime? appointmentStartAt;
  final DateTime? appointmentEndAt;
  final String accessStatus;
  final List<String> availableActions;
}

class AppointmentHouseSummary {
  const AppointmentHouseSummary({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.address,
  });

  factory AppointmentHouseSummary.fromJson(Map<String, dynamic>? json) {
    return AppointmentHouseSummary(
      id: json?['id'] as String? ?? '',
      title: json?['title'] as String? ?? '',
      coverImage: json?['coverImage'] as String? ?? '',
      address: json?['address'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final String coverImage;
  final String address;
}

class AppointmentHost {
  const AppointmentHost({
    required this.userId,
    required this.name,
    required this.phoneMasked,
    required this.canContact,
  });

  factory AppointmentHost.fromJson(Map<String, dynamic> json) {
    return AppointmentHost(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneMasked: json['phoneMasked'] as String? ?? '',
      canContact: json['canContact'] as bool? ?? false,
    );
  }

  final String userId;
  final String name;
  final String phoneMasked;
  final bool canContact;
}

class AppointmentStatusLog {
  const AppointmentStatusLog({
    required this.fromStatus,
    required this.toStatus,
    required this.reason,
    required this.createdAt,
  });

  factory AppointmentStatusLog.fromJson(Map<String, dynamic> json) {
    return AppointmentStatusLog(
      fromStatus: json['fromStatus'] as String? ?? '',
      toStatus: json['toStatus'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      createdAt: _date(json['createdAt']),
    );
  }

  final String fromStatus;
  final String toStatus;
  final String reason;
  final DateTime? createdAt;
}

class AppointmentDetail {
  const AppointmentDetail({
    required this.id,
    required this.status,
    required this.sourceType,
    required this.sourceLabel,
    required this.viewingMode,
    required this.viewingModeLabel,
    required this.appointmentStartAt,
    required this.appointmentEndAt,
    required this.proposedStartAt,
    required this.proposedEndAt,
    required this.rescheduleReason,
    required this.house,
    required this.host,
    required this.contactName,
    required this.contactPhone,
    required this.remark,
    required this.meetingPoint,
    required this.viewingInstruction,
    required this.rejectReason,
    required this.cancelReason,
    required this.checkinCode,
    required this.accessStatus,
    required this.availableActions,
    required this.statusLogs,
    this.accessValidFrom,
    this.accessValidTo,
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    final hostJson = json['host'];
    return AppointmentDetail(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING_CONFIRMATION',
      sourceType: json['sourceType'] as String? ?? 'LANDLORD',
      sourceLabel: json['sourceLabel'] as String? ?? '个人房源',
      viewingMode: json['viewingMode'] as String? ?? 'LANDLORD_HOSTED',
      viewingModeLabel: json['viewingModeLabel'] as String? ?? '房东陪同',
      appointmentStartAt: _date(json['appointmentStartAt']),
      appointmentEndAt: _date(json['appointmentEndAt']),
      proposedStartAt: _date(json['proposedStartAt']),
      proposedEndAt: _date(json['proposedEndAt']),
      rescheduleReason: json['rescheduleReason'] as String? ?? '',
      house: AppointmentHouseSummary.fromJson(
        json['house'] as Map<String, dynamic>?,
      ),
      host: hostJson is Map<String, dynamic>
          ? AppointmentHost.fromJson(hostJson)
          : null,
      contactName: json['contactName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      meetingPoint: json['meetingPoint'] as String? ?? '',
      viewingInstruction: json['viewingInstruction'] as String? ?? '',
      rejectReason: json['rejectReason'] as String? ?? '',
      cancelReason: json['cancelReason'] as String? ?? '',
      checkinCode: json['checkinCode'] as String? ?? '',
      accessStatus: json['accessStatus'] as String? ?? 'NOT_REQUIRED',
      accessValidFrom: _date(json['accessValidFrom']),
      accessValidTo: _date(json['accessValidTo']),
      availableActions: (json['availableActions'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      statusLogs: (json['statusLogs'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AppointmentStatusLog.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final String status;
  final String sourceType;
  final String sourceLabel;
  final String viewingMode;
  final String viewingModeLabel;
  final DateTime? appointmentStartAt;
  final DateTime? appointmentEndAt;
  final DateTime? proposedStartAt;
  final DateTime? proposedEndAt;
  final String rescheduleReason;
  final AppointmentHouseSummary house;
  final AppointmentHost? host;
  final String contactName;
  final String contactPhone;
  final String remark;
  final String meetingPoint;
  final String viewingInstruction;
  final String rejectReason;
  final String cancelReason;
  final String checkinCode;
  final String accessStatus;
  final DateTime? accessValidFrom;
  final DateTime? accessValidTo;
  final List<String> availableActions;
  final List<AppointmentStatusLog> statusLogs;
}

class AppointmentAccess {
  const AppointmentAccess({
    required this.status,
    required this.validFrom,
    required this.validTo,
    required this.bluetoothEnabled,
    required this.lockMac,
    required this.lockData,
    required this.passcodeAvailable,
    required this.passcode,
    this.passcodeValidFrom,
    this.passcodeValidTo,
  });

  factory AppointmentAccess.fromJson(Map<String, dynamic> json) {
    final bluetooth = json['bluetooth'] as Map<String, dynamic>? ?? const {};
    final passcode = json['passcode'] as Map<String, dynamic>? ?? const {};
    return AppointmentAccess(
      status: json['accessStatus'] as String? ?? 'PENDING',
      validFrom: _date(json['validFrom']),
      validTo: _date(json['validTo']),
      bluetoothEnabled: bluetooth['enabled'] as bool? ?? false,
      lockMac: bluetooth['lockMac'] as String? ?? '',
      lockData: bluetooth['lockData'] as String? ?? '',
      passcodeAvailable: passcode['available'] as bool? ?? false,
      passcode: passcode['value'] as String? ?? '',
      passcodeValidFrom: _date(passcode['validFrom']),
      passcodeValidTo: _date(passcode['validTo']),
    );
  }

  final String status;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool bluetoothEnabled;
  final String lockMac;
  final String lockData;
  final bool passcodeAvailable;
  final String passcode;
  final DateTime? passcodeValidFrom;
  final DateTime? passcodeValidTo;
}

DateTime? _date(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
