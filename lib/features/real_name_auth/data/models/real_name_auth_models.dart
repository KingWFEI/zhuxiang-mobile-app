enum RealNameAuthStatus {
  unverified,
  verifying,
  verified,
  failed,
  expired,
  canceled,
  unknown,
}

RealNameAuthStatus parseRealNameAuthStatus(Object? value) {
  return switch (value?.toString().toUpperCase()) {
    'UNVERIFIED' => RealNameAuthStatus.unverified,
    'VERIFYING' => RealNameAuthStatus.verifying,
    'VERIFIED' => RealNameAuthStatus.verified,
    'FAILED' => RealNameAuthStatus.failed,
    'EXPIRED' => RealNameAuthStatus.expired,
    'CANCELED' => RealNameAuthStatus.canceled,
    _ => RealNameAuthStatus.unknown,
  };
}

class RealNameAuthStatusResponse {
  const RealNameAuthStatusResponse({
    required this.authStatus,
    this.realNameAuthNo,
    this.authUrl,
    this.authUrlExpireTime,
    this.realNameMasked,
    this.idCardMasked,
    this.accountMobileMasked,
    this.verifiedMobileMasked,
    this.verifiedAt,
  });

  final RealNameAuthStatus authStatus;
  final String? realNameAuthNo;
  final String? authUrl;
  final DateTime? authUrlExpireTime;
  final String? realNameMasked;
  final String? idCardMasked;
  final String? accountMobileMasked;
  final String? verifiedMobileMasked;
  final DateTime? verifiedAt;

  factory RealNameAuthStatusResponse.fromJson(Map<String, dynamic> json) {
    return RealNameAuthStatusResponse(
      authStatus: parseRealNameAuthStatus(json['authStatus']),
      realNameAuthNo: _stringOrNull(json['realNameAuthNo']),
      authUrl: _stringOrNull(json['authUrl']),
      authUrlExpireTime: _dateOrNull(json['authUrlExpireTime']),
      realNameMasked: _stringOrNull(json['realNameMasked']),
      idCardMasked: _stringOrNull(json['idCardMasked']),
      accountMobileMasked: _stringOrNull(json['accountMobileMasked']),
      verifiedMobileMasked: _stringOrNull(json['verifiedMobileMasked']),
      verifiedAt: _dateOrNull(json['verifiedAt']),
    );
  }
}

typedef RealNameAuthStartResponse = RealNameAuthStatusResponse;
typedef RealNameAuthRefreshResponse = RealNameAuthStatusResponse;

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _dateOrNull(Object? value) {
  final text = _stringOrNull(value);
  return text == null ? null : DateTime.tryParse(text);
}
