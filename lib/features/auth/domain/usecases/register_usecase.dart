import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String phone,
    required String code,
    required String password,
  }) {
    return _repository.register(phone: phone, code: code, password: password);
  }
}
