import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

final mockAuthDatasourceProvider = Provider<MockAuthDatasource>((ref) {
  return MockAuthDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(mockAuthDatasourceProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    return AuthController(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      initialUser: repository.currentUser,
    );
  },
);

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    AuthUser? initialUser,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _logoutUseCase = logoutUseCase,
       super(AuthState(user: initialUser));

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  Future<bool> loginWithCode({
    required String phone,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _loginUseCase.withCode(phone: phone, code: code);
      state = AuthState(user: user);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  Future<bool> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _loginUseCase.withPassword(
        phone: phone,
        password: password,
      );
      state = AuthState(user: user);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _registerUseCase(phone: phone, code: code, password: password);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _logoutUseCase();
    state = state.copyWith(clearUser: true, isLoading: false, clearError: true);
  }

  String _messageFromError(Object error) {
    if (error is MockAuthException) return error.message;
    return '操作失败，请稍后重试';
  }
}
