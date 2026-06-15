class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.avatarUrl,
    required this.isVerified,
  });

  final String id;
  final String phone;
  final String nickname;
  final String avatarUrl;
  final bool isVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
    };
  }

  String get maskedPhone {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}
