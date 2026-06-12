import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);

  final MockAuthDatasource _datasource;

  @override
  AuthUser? get currentUser => _datasource.currentUser;

  @override
  Future<AuthUser> loginWithCode({
    required String phone,
    required String code,
  }) {
    return _datasource.loginWithCode(phone: phone, code: code);
  }

  @override
  Future<AuthUser> loginWithPassword({
    required String phone,
    required String password,
  }) {
    return _datasource.loginWithPassword(phone: phone, password: password);
  }

  @override
  Future<AuthUser> register({
    required String phone,
    required String code,
    required String password,
  }) {
    return _datasource.register(phone: phone, code: code, password: password);
  }

  @override
  Future<void> logout() {
    return _datasource.logout();
  }
}
