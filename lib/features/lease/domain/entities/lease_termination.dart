class LeaseTerminationAttachment {
  const LeaseTerminationAttachment({
    required this.url,
    required this.type,
    required this.name,
  });

  final String url;
  final String type;
  final String name;

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type, 'name': name};
  }
}

class TerminationCheck {
  const TerminationCheck({
    required this.canApply,
    required this.hasPendingApplication,
    required this.hasUnpaidBills,
    required this.message,
    this.existingApplication,
  });

  final bool canApply;
  final bool hasPendingApplication;
  final bool hasUnpaidBills;
  final String message;
  final TerminationApplication? existingApplication;

  factory TerminationCheck.fromJson(Map<String, dynamic> json) {
    final existing = json['existingApplication'];
    return TerminationCheck(
      canApply: json['canApply'] as bool? ?? false,
      hasPendingApplication: json['hasPendingApplication'] as bool? ?? false,
      hasUnpaidBills: json['hasUnpaidBills'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      existingApplication: existing is Map<String, dynamic>
          ? TerminationApplication.fromJson(existing)
          : null,
    );
  }
}

class TerminationApplication {
  const TerminationApplication({
    required this.id,
    required this.applicationNo,
    required this.status,
    required this.statusText,
  });

  final String id;
  final String applicationNo;
  final String status;
  final String statusText;

  factory TerminationApplication.fromJson(Map<String, dynamic> json) {
    return TerminationApplication(
      id: _string(json, ['id', 'applicationId']),
      applicationNo: _string(json, ['applicationNo', 'application_no']),
      status: _string(json, ['status'], fallback: 'pending_review'),
      statusText: _string(json, ['statusText', 'status_text'], fallback: '待审核'),
    );
  }

  static String _string(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return fallback;
  }
}

class LeaseTerminationRequest {
  const LeaseTerminationRequest({
    required this.reason,
    required this.expectedMoveOutDate,
    required this.hasMovedOut,
    required this.contactName,
    required this.contactPhone,
    required this.remark,
    required this.attachments,
  });

  final String reason;
  final DateTime expectedMoveOutDate;
  final bool hasMovedOut;
  final String contactName;
  final String contactPhone;
  final String remark;
  final List<LeaseTerminationAttachment> attachments;

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'expectedMoveOutDate': formatDate(expectedMoveOutDate),
      'hasMovedOut': hasMovedOut,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'remark': remark,
      'attachments': attachments.map((item) => item.toJson()).toList(),
    };
  }

  static String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}

