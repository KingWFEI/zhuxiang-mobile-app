import '../models/auth_user_model.dart';

class MockAuthDatasource {
  MockAuthDatasource()
    : _users = [
        const AuthUserModel(
          id: 'mock-user-001',
          phone: '13800138000',
          nickname: 'King',
          avatarUrl: '',
          isVerified: true,
          password: '123456',
        ),
      ];

  static const validCode = '123456';

  final List<AuthUserModel> _users;
  AuthUserModel? _currentUser;

  AuthUserModel? get currentUser => _currentUser;

  Future<AuthUserModel> login({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final user = _users.where((item) => item.phone == phone).firstOrNull;
    if (user == null || code != validCode) {
      throw const MockAuthException('手机号或验证码不正确');
    }
    _currentUser = user;
    return user;
  }

  Future<AuthUserModel> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code != validCode) {
      throw const MockAuthException('验证码不正确');
    }
    final exists = _users.any((item) => item.phone == phone);
    if (exists) {
      throw const MockAuthException('该手机号已注册');
    }

    final user = AuthUserModel(
      id: 'mock-user-${_users.length + 1}'.padLeft(13, '0'),
      phone: phone,
      nickname: '住享用户',
      avatarUrl: '',
      isVerified: false,
      password: password,
    );
    _users.add(user);
    return user;
  }

  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
  }
}

class MockAuthException implements Exception {
  const MockAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
