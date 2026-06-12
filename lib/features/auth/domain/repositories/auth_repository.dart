import '../entities/auth_user.dart';

abstract class AuthRepository {
  AuthUser? get currentUser;

  Future<AuthUser> loginWithCode({required String phone, required String code});

  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  });

  Future<AuthUser> register({
    required String phone,
    required String code,
    required String password,
  });

  Future<void> logout();
}
