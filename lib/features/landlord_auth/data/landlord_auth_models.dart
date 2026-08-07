class LandlordAuthProof {
  const LandlordAuthProof({
    required this.proofType,
    required this.fileId,
    required this.fileUrl,
  });

  final String proofType;
  final String fileId;
  final String fileUrl;

  factory LandlordAuthProof.fromJson(Map<String, dynamic> json) =>
      LandlordAuthProof(
        proofType: json['proofType'] as String? ?? 'OTHER',
        fileId: json['fileId'] as String? ?? '',
        fileUrl: json['fileUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'proofType': proofType,
    'fileId': fileId,
    'fileUrl': fileUrl,
  };
}

class LandlordAuthApplication {
  const LandlordAuthApplication({
    required this.id,
    required this.applicationNo,
    required this.status,
    required this.realName,
    required this.idCardMasked,
    required this.idCardFrontUrl,
    required this.idCardBackUrl,
    required this.contactPhone,
    required this.proofs,
    this.contactWechat,
    this.contactEmail,
    this.contactAddress,
    this.preferredContactTime,
    this.applicantNote,
    this.rejectReason,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String applicationNo;
  final String status;
  final String realName;
  final String idCardMasked;
  final String idCardFrontUrl;
  final String idCardBackUrl;
  final String contactPhone;
  final String? contactWechat;
  final String? contactEmail;
  final String? contactAddress;
  final String? preferredContactTime;
  final String? applicantNote;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final List<LandlordAuthProof> proofs;

  factory LandlordAuthApplication.fromJson(Map<String, dynamic> json) =>
      LandlordAuthApplication(
        id: json['id'] as String? ?? '',
        applicationNo: json['applicationNo'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        realName: json['realName'] as String? ?? '',
        idCardMasked: json['idCardMasked'] as String? ?? '',
        idCardFrontUrl: json['idCardFrontUrl'] as String? ?? '',
        idCardBackUrl: json['idCardBackUrl'] as String? ?? '',
        contactPhone: json['contactPhone'] as String? ?? '',
        contactWechat: json['contactWechat'] as String?,
        contactEmail: json['contactEmail'] as String?,
        contactAddress: json['contactAddress'] as String?,
        preferredContactTime: json['preferredContactTime'] as String?,
        applicantNote: json['applicantNote'] as String?,
        rejectReason: json['rejectReason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
        proofs: (json['proofs'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(LandlordAuthProof.fromJson)
            .toList(),
      );
}

class LandlordAuthStatus {
  const LandlordAuthStatus({
    required this.status,
    required this.canSubmit,
    required this.landlord,
    this.latest,
  });

  final String status;
  final bool canSubmit;
  final bool landlord;
  final LandlordAuthApplication? latest;

  factory LandlordAuthStatus.fromJson(Map<String, dynamic> json) {
    final latest = json['latestApplication'];
    return LandlordAuthStatus(
      status: json['status'] as String? ?? 'UNVERIFIED',
      canSubmit: json['canSubmit'] as bool? ?? true,
      landlord: json['landlord'] as bool? ?? false,
      latest: latest is Map<String, dynamic>
          ? LandlordAuthApplication.fromJson(latest)
          : null,
    );
  }
}

class UploadedAuthFile {
  const UploadedAuthFile({required this.url, required this.fileId});
  final String url;
  final String fileId;
  factory UploadedAuthFile.fromJson(Map<String, dynamic> json) =>
      UploadedAuthFile(
        url: json['url'] as String? ?? '',
        fileId: json['fileId'] as String? ?? '',
      );
}
