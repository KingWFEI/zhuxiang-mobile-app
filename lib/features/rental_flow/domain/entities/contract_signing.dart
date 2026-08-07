class ContractSignEntry {
  const ContractSignEntry({
    required this.contractStatus,
    required this.currentUserRole,
    required this.currentUserSigned,
    required this.signUrl,
  });

  final String contractStatus;
  final String currentUserRole;
  final bool currentUserSigned;
  final String? signUrl;

  bool get isCompleted => contractStatus.toUpperCase() == 'COMPLETED';
}

class ContractSigningStatus {
  const ContractSigningStatus({
    required this.contractStatus,
    required this.currentUserSigned,
    required this.lessorSigned,
    required this.tenantSigned,
    required this.downloadAvailable,
    this.signedAt,
  });

  final String contractStatus;
  final bool currentUserSigned;
  final bool lessorSigned;
  final bool tenantSigned;
  final bool downloadAvailable;
  final DateTime? signedAt;

  bool get isCompleted => contractStatus.toUpperCase() == 'COMPLETED';

  /// 新租房流程中，租客签署完成即可进入支付，无需等待房东签署。
  bool get readyForPayment => tenantSigned;
}

class ContractDownload {
  const ContractDownload({
    required this.fileName,
    required this.downloadUrl,
    this.certificateDownloadUrl,
  });

  final String fileName;
  final String downloadUrl;
  final String? certificateDownloadUrl;
}
