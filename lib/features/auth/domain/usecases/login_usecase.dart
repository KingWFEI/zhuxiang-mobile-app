import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String phone, required String code}) {
    return _repository.login(phone: phone, code: code);
  }
}
