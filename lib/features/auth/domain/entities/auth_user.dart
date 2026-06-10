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

  String get maskedPhone {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}
