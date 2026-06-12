import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> withCode({required String phone, required String code}) {
    return _repository.loginWithCode(phone: phone, code: code);
  }

  Future<AuthUser> withPassword({
    required String phone,
    required String password,
  }) {
    return _repository.loginWithPassword(phone: phone, password: password);
  }
}
