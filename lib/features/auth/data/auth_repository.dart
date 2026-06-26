import '../domain/entities/auth_user.dart';

abstract class AuthRepository {
  AuthUser? get currentUser;

  Future<int> sendSmsCode({required String phone, required String scene});

  Future<AuthUser> loginWithCode({required String phone, required String code});

  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  });

  Future<AuthUser> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  });

  Future<AuthUser?> restoreSession();

  Future<void> refreshSession();

  Future<void> updateUser(AuthUser user);

  Future<void> logout();
}
