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
      'expectedMoveOutDate': _formatDate(expectedMoveOutDate),
      'hasMovedOut': hasMovedOut,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'remark': remark,
      'attachments': attachments.map((item) => item.toJson()).toList(),
    };
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}

class LeaseTerminationApplication {
  const LeaseTerminationApplication({
    required this.id,
    required this.applicationNo,
    required this.status,
    required this.statusText,
  });

  final String id;
  final String applicationNo;
  final String status;
  final String statusText;
}
