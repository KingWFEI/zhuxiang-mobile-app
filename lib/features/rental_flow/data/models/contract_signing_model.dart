import '../../domain/entities/contract_signing.dart';

class ContractSignEntryModel extends ContractSignEntry {
  const ContractSignEntryModel({
    required super.contractStatus,
    required super.currentUserRole,
    required super.currentUserSigned,
    required super.signUrl,
  });

  factory ContractSignEntryModel.fromJson(Map<String, dynamic> json) {
    return ContractSignEntryModel(
      contractStatus: json['contractStatus'] as String? ?? '',
      currentUserRole: json['currentUserRole'] as String? ?? '',
      currentUserSigned: json['currentUserSigned'] as bool? ?? false,
      signUrl: _nonEmptyString(json['signUrl']),
    );
  }
}

class ContractSigningStatusModel extends ContractSigningStatus {
  const ContractSigningStatusModel({
    required super.contractStatus,
    required super.currentUserSigned,
    required super.lessorSigned,
    required super.tenantSigned,
    required super.downloadAvailable,
    super.signedAt,
  });

  factory ContractSigningStatusModel.fromJson(Map<String, dynamic> json) {
    return ContractSigningStatusModel(
      contractStatus: json['contractStatus'] as String? ?? '',
      currentUserSigned: json['currentUserSigned'] as bool? ?? false,
      lessorSigned: json['lessorSigned'] as bool? ?? false,
      tenantSigned: json['tenantSigned'] as bool? ?? false,
      downloadAvailable: json['downloadAvailable'] as bool? ?? false,
      signedAt: DateTime.tryParse(json['signedAt'] as String? ?? ''),
    );
  }
}

class ContractDownloadModel extends ContractDownload {
  const ContractDownloadModel({
    required super.fileName,
    required super.downloadUrl,
    super.certificateDownloadUrl,
  });

  factory ContractDownloadModel.fromJson(Map<String, dynamic> json) {
    return ContractDownloadModel(
      fileName: json['fileName'] as String? ?? '租房合同.pdf',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      certificateDownloadUrl: _nonEmptyString(json['certificateDownloadUrl']),
    );
  }
}

String? _nonEmptyString(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}
