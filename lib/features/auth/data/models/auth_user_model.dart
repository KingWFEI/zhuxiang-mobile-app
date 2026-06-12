import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.phone,
    required super.nickname,
    required super.avatarUrl,
    required super.isVerified,
    required this.password,
  });

  final String password;

  AuthUserModel copyWith({
    String? id,
    String? phone,
    String? nickname,
    String? avatarUrl,
    bool? isVerified,
    String? password,
  }) {
    return AuthUserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      password: password ?? this.password,
    );
  }
}
