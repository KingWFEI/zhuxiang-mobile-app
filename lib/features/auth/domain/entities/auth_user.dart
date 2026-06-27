import 'user_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.avatarUrl,
    required this.isVerified,
    this.role = UserRole.tenant,
    this.hasPassword = false,
  });

  final String id;
  final String phone;
  final String nickname;
  final String avatarUrl;
  final bool isVerified;
  final UserRole role;
  final bool hasPassword;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      role: UserRole.fromCode(json['role'] as String?),
      hasPassword: json['hasPassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'role': role.code,
      'hasPassword': hasPassword,
    };
  }

  String get maskedPhone {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}
