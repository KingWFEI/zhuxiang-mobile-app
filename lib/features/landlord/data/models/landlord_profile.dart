class LandlordProfile {
  const LandlordProfile({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.coverImageUrl,
    required this.slogan,
    required this.introduction,
    required this.isVerified,
    required this.rating,
    required this.rentedCount,
    required this.responseDescription,
    required this.serviceArea,
    required this.serviceYears,
    required this.profileTags,
    this.phone,
    this.wechat,
    this.email,
    required this.contactTime,
    required this.showPhone,
    required this.showWechat,
    required this.showEmail,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final String coverImageUrl;
  final String slogan;
  final String introduction;
  final bool isVerified;
  final double rating;
  final int rentedCount;
  final String responseDescription;
  final String serviceArea;
  final int serviceYears;
  final List<String> profileTags;
  final String? phone;
  final String? wechat;
  final String? email;
  final String contactTime;
  final bool showPhone;
  final bool showWechat;
  final bool showEmail;

  bool get hasPublicContact =>
      (phone?.isNotEmpty ?? false) ||
      (wechat?.isNotEmpty ?? false) ||
      (email?.isNotEmpty ?? false);

  factory LandlordProfile.fromJson(Map<String, dynamic> json) {
    return LandlordProfile(
      userId: '${json['userId'] ?? ''}',
      name: '${json['name'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? ''}',
      coverImageUrl: '${json['coverImageUrl'] ?? ''}',
      slogan: '${json['slogan'] ?? ''}',
      introduction: '${json['introduction'] ?? ''}',
      isVerified: json['isVerified'] == true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      rentedCount: (json['rentedCount'] as num?)?.toInt() ?? 0,
      responseDescription: '${json['responseDescription'] ?? ''}',
      serviceArea: '${json['serviceArea'] ?? ''}',
      serviceYears: (json['serviceYears'] as num?)?.toInt() ?? 0,
      profileTags:
          (json['profileTags'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toList() ??
          const [],
      phone: _nullableString(json['phone']),
      wechat: _nullableString(json['wechat']),
      email: _nullableString(json['email']),
      contactTime: '${json['contactTime'] ?? ''}',
      showPhone: json['showPhone'] == true,
      showWechat: json['showWechat'] == true,
      showEmail: json['showEmail'] == true,
    );
  }
}

class UpdateLandlordProfileRequest {
  const UpdateLandlordProfileRequest({
    required this.name,
    required this.coverImageUrl,
    required this.slogan,
    required this.introduction,
    required this.serviceArea,
    required this.serviceYears,
    required this.profileTags,
    required this.phone,
    required this.wechat,
    required this.email,
    required this.contactTime,
    required this.responseDescription,
    required this.showPhone,
    required this.showWechat,
    required this.showEmail,
  });

  final String name;
  final String coverImageUrl;
  final String slogan;
  final String introduction;
  final String serviceArea;
  final int serviceYears;
  final List<String> profileTags;
  final String phone;
  final String wechat;
  final String email;
  final String contactTime;
  final String responseDescription;
  final bool showPhone;
  final bool showWechat;
  final bool showEmail;

  Map<String, dynamic> toJson() => {
    'name': name,
    'coverImageUrl': coverImageUrl,
    'slogan': slogan,
    'introduction': introduction,
    'serviceArea': serviceArea,
    'serviceYears': serviceYears,
    'profileTags': profileTags,
    'phone': phone,
    'wechat': wechat,
    'email': email,
    'contactTime': contactTime,
    'responseDescription': responseDescription,
    'showPhone': showPhone,
    'showWechat': showWechat,
    'showEmail': showEmail,
  };
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
