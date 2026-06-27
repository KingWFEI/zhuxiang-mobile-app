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

// ═══════════════════════════════════════════════════════════════════
// Provider 定义
// ═══════════════════════════════════════════════════════════════════

/// 认证 API 服务
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Token 持久化存储
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return StorageService.tokenStorage;
});

/// 游客模式状态存储
final guestModeStorageProvider = Provider<GuestModeStorage>((ref) {
  return StorageService.guestModeStorage;
});

/// 认证数据仓库（对接 API + 本地存储）
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// 认证状态控制器（全局唯一，驱动路由守卫）
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      AuthUseCases(ref.watch(authRepositoryProvider)),
      ref.watch(guestModeStorageProvider),
    );
  },
);

// ═══════════════════════════════════════════════════════════════════
// 认证状态
// ═══════════════════════════════════════════════════════════════════

/// 全局认证状态
///
/// 由 [AuthController] 管理，通过 [authControllerProvider] 暴露。
/// GoRouter 路由守卫根据此状态决定拦截或放行。
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isSendingCode = false,
    this.isInitialized = false,
    this.isGuest = false,
    this.errorMessage,
  });

  /// 当前登录用户，null 表示未登录
  final AuthUser? user;
  /// 是否正在执行登录/注册/登出等操作
  final bool isLoading;
  /// 是否正在发送短信验证码
  final bool isSendingCode;
  /// 会话恢复是否已完成（启动页使用）
  final bool isInitialized;
  /// 是否处于游客模式
  final bool isGuest;
  /// 最近一次操作的错误消息
  final String? errorMessage;

  /// 是否已登录
  bool get isLoggedIn => user != null;

  /// 创建修改部分字段的新状态
  ///
  /// [clearUser] 设为 true 可将 user 置 null（用于登出场景）。
  /// [clearError] 设为 true 可清除错误消息。
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

// ═══════════════════════════════════════════════════════════════════
// 认证控制器
// ═══════════════════════════════════════════════════════════════════

/// 认证业务逻辑控制器
///
/// 管理登录、注册、登出、游客模式、会话恢复等全部认证相关操作。
/// 通过 [StateNotifier] 模式修改 [AuthState]，驱动 UI 和路由守卫更新。
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._useCases, this._guestModeStorage)
    : super(const AuthState());

  final AuthUseCases _useCases;
  final GuestModeStorage _guestModeStorage;

  /// 缓存恢复 Future，防止重复调用
  Future<void>? _restoreFuture;

  // ── 会话管理 ─────────────────────────────────────────────────

  /// 恢复登录会话（启动时调用）
  ///
  /// 从本地存储读取 Token → 若过期尝试刷新 → 得到用户信息。
  /// 同一时间只会执行一次（通过 [_restoreFuture] 缓存）。
  Future<void> restoreSession() {
    return _restoreFuture ??= _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _useCases.restoreSession();
      if (!mounted) return;
      if (user != null) {
        // 登录用户清除游客标记
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

  /// 刷新 Token
  ///
  /// 失败时清除当前用户，需要重新登录。
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

  // ── 短信验证码 ───────────────────────────────────────────────

  /// 发送短信验证码
  ///
  /// [phone] 手机号，[scene] 使用场景（login / register）。
  /// 返回有效时长（秒），失败返回 null。
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

  // ── 登录 ─────────────────────────────────────────────────────

  /// 验证码登录
  ///
  /// 成功返回 true 并跳转首页；失败返回 false，错误信息在 [AuthState.errorMessage]。
  Future<bool> loginWithCode({required String phone, required String code}) {
    return _runAuthentication(
      () => _useCases.loginWithCode(phone: phone, code: code),
    );
  }

  /// 密码登录
  Future<bool> loginWithPassword({
    required String phone,
    required String password,
  }) {
    return _runAuthentication(
      () => _useCases.loginWithPassword(phone: phone, password: password),
    );
  }

  // ── 注册 ─────────────────────────────────────────────────────

  /// 注册新用户
  ///
  /// 需提供手机号、验证码、密码和昵称。
  /// 成功后自动登录并跳转首页。
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

  // ── 用户信息 ─────────────────────────────────────────────────

  /// 更新当前用户信息（昵称、头像等）
  ///
  /// 修改会同步到本地存储和全局状态。
  Future<void> updateUser(AuthUser user) async {
    await _useCases.updateUser(user);
    if (!mounted) return;
    state = state.copyWith(user: user);
  }

  // ── 游客模式 ─────────────────────────────────────────────────

  /// 进入游客模式
  ///
  /// 游客可浏览租户端部分页面，无需登录。
  Future<void> enterGuestMode() async {
    await _guestModeStorage.enable();
    if (!mounted) return;
    state = AuthState(isGuest: true, isInitialized: true);
  }

  // ── 登出 ─────────────────────────────────────────────────────

  /// 退出登录
  ///
  /// 清除本地 Token、清除游客标记、重置认证状态。
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

  // ── 内部方法 ─────────────────────────────────────────────────

  /// 执行登录/注册流程的通用模板
  ///
  /// 设置 loading 状态 → 执行认证 → 成功则清除游客模式并写入用户信息。
  /// 返回 true 表示认证成功。
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

  /// 将异常转为用户可读的错误消息
  String _messageFromError(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    return '操作失败，请稍后重试';
  }
}
