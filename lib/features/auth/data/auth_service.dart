import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import 'auth_models.dart';

// 用户登录注册相关接口服务
class AuthService {
  final ApiClient _apiClient = ApiClient();
  // 发送验证码
  Future<SmsCodeResult> sendSmsCode({
    required String phone,
    required String scene,
  }) async {
    final result = await _apiClient.post(
      '/auth/sms-code',
      data: {'phone': phone, 'scene': scene},
    );
    return result.unwrapData(SmsCodeResult.fromJson);
  }
  // 验证码登录/注册
  Future<AuthResult> loginByCode({
    required String phone,
    required String code,
  }) async {
    final result = await _apiClient.post(
      '/auth/login/code',
      data: {'phone': phone, 'code': code},
    );
    return result.unwrapData(AuthResult.fromJson);
  }

  // 密码登录
  Future<AuthResult> loginByPassword({
    required String phone,
    required String password,
  }) async {
    final result = await _apiClient.post(
      '/auth/login/password',
      data: {'phone': phone, 'password': password},
    );
    return result.unwrapData(AuthResult.fromJson);
  }
  // 注册
  Future<AuthResult> register({
    required String phone,
    required String code,
    required String password,
    required String nickname,
  }) async {
    final result = await _apiClient.post(
      '/auth/register',
      data: {
        'phone': phone,
        'code': code,
        'password': password,
        'nickname': nickname,
      },
    );
    return result.unwrapData(AuthResult.fromJson);
  }
  // 刷新Token
  Future<TokenResult> refresh(String refreshToken) async {
    final result = await _apiClient.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return result.unwrapData(TokenResult.fromJson);
  }

  Future<bool> logout(String refreshToken) async {
    final result = await _apiClient.post(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
    return result.unwrapValue((data) => data as bool);
  }
}
