import '../data/auth_repository.dart';
import 'entities/auth_user.dart';

class AuthUseCases {
  const AuthUseCases(this._repository);

  final AuthRepository _repository;

  Future<int> sendSmsCode({required String phone, required String scene}) {
    return _repository.sendSmsCode(phone: phone, scene: scene);
  }

  Future<AuthUser> loginWithCode({
    required String phone,
    required String code,
  }) {
    return _repository.loginWithCode(phone: phone, code: code);
  }

  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  }) {
    return _repository.loginWithPassword(phone: phone, password: password);
  }

  Future<AuthUser> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  }) {
    return _repository.register(
      phone: phone,
      code: code,
      password: password,
      nickname: nickname,
    );
  }

  Future<AuthUser?> restoreSession() {
    return _repository.restoreSession();
  }

  Future<void> refreshSession() {
    return _repository.refreshSession();
  }

  Future<void> logout() {
    return _repository.logout();
  }
}
