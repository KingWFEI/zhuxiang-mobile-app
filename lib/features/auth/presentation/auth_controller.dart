import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/guest_mode_storage.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/auth_repository_impl.dart';
import '../data/auth_service.dart';
import '../domain/auth_usecases.dart';
import '../domain/entities/auth_user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return StorageService.tokenStorage;
});

final guestModeStorageProvider = Provider<GuestModeStorage>((ref) {
  return StorageService.guestModeStorage;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      AuthUseCases(ref.watch(authRepositoryProvider)),
      ref.watch(guestModeStorageProvider),
    );
  },
);

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isSendingCode = false,
    this.isInitialized = false,
    this.isGuest = false,
    this.errorMessage,
  });

  final AuthUser? user;
  final bool isLoading;
  final bool isSendingCode;
  final bool isInitialized;
  final bool isGuest;
  final String? errorMessage;

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool clearUser = false,
    bool? isLoading,
    bool? isSendingCode,
    bool? isInitialized,
    bool? isGuest,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      isInitialized: isInitialized ?? this.isInitialized,
      isGuest: isGuest ?? this.isGuest,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._useCases, this._guestModeStorage)
    : super(const AuthState());

  final AuthUseCases _useCases;
  final GuestModeStorage _guestModeStorage;
  Future<void>? _restoreFuture;

  Future<void> restoreSession() {
    return _restoreFuture ??= _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _useCases.restoreSession();
      if (!mounted) return;
      if (user != null) {
        await _guestModeStorage.clear();
      }
      if (!mounted) return;
      state = AuthState(
        user: user,
        isGuest: user == null && _guestModeStorage.isEnabled,
        isInitialized: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = AuthState(
        isInitialized: true,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<int?> sendSmsCode({
    required String phone,
    required String scene,
  }) async {
    state = state.copyWith(isSendingCode: true, clearError: true);
    try {
      final expiresIn = await _useCases.sendSmsCode(phone: phone, scene: scene);
      state = state.copyWith(isSendingCode: false, clearError: true);
      return expiresIn;
    } catch (error) {
      state = state.copyWith(
        isSendingCode: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<bool> loginWithCode({required String phone, required String code}) {
    return _runAuthentication(
      () => _useCases.loginWithCode(phone: phone, code: code),
    );
  }

  Future<bool> loginWithPassword({
    required String phone,
    required String password,
  }) {
    return _runAuthentication(
      () => _useCases.loginWithPassword(phone: phone, password: password),
    );
  }

  Future<bool> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  }) {
    return _runAuthentication(
      () => _useCases.register(
        phone: phone,
        code: code,
        password: password,
        nickname: nickname,
      ),
    );
  }

  Future<bool> refreshSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.refreshSession();
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        clearUser: true,
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  Future<void> enterGuestMode() async {
    await _guestModeStorage.enable();
    if (!mounted) return;
    state = AuthState(isGuest: true, isInitialized: true);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _useCases.logout();
      await _guestModeStorage.clear();
      state = AuthState(isInitialized: state.isInitialized);
    } catch (error) {
      state = AuthState(
        isInitialized: state.isInitialized,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<bool> _runAuthentication(
    Future<AuthUser> Function() authenticate,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await authenticate();
      await _guestModeStorage.clear();
      if (!mounted) return false;
      state = AuthState(user: user, isInitialized: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
      return false;
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return '操作失败，请稍后重试';
  }
}
