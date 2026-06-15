import '../domain/entities/auth_user.dart';

class SmsCodeResult {
  const SmsCodeResult({required this.expiresIn});

  final int expiresIn;

  factory SmsCodeResult.fromJson(Map<String, dynamic> json) {
    return SmsCodeResult(expiresIn: (json['expiresIn'] as num).toInt());
  }
}

class TokenResult {
  const TokenResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory TokenResult.fromJson(Map<String, dynamic> json) {
    return TokenResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
    );
  }
}

class AuthResult extends TokenResult {
  const AuthResult({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresIn,
    required this.user,
  });

  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
