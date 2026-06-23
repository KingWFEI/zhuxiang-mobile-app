import 'package:dio/dio.dart';
import 'package:zhuxiang_app/core/network/api_client.dart';
import 'package:zhuxiang_app/core/network/api_exception.dart';

import '../models/profile_models.dart';

class ProfileService {
  const ProfileService(this.apiClient);

  final ApiClient apiClient;

  /// 获取当前租约房源信息，无租约时返回 null。
  Future<CurrentHome?> getCurrentHome() async {
    final result = await apiClient.get('/profile/current-home');

    return result.when(
      success: (response) => _extractData(response, CurrentHome.fromJson),
      failure: (message, error) {
        throw error is ApiException
            ? error
            : ApiException(
                type: ApiExceptionType.unknown,
                message: message,
                cause: error,
              );
      },
    );
  }

  /// 获取门锁展示信息，无门锁时返回 null。
  Future<LockInfo?> getLockInfo() async {
    final result = await apiClient.get('/profile/lock');

    return result.when(
      success: (response) => _extractData(response, LockInfo.fromJson),
      failure: (message, error) {
        throw error is ApiException
            ? error
            : ApiException(
                type: ApiExceptionType.unknown,
                message: message,
                cause: error,
              );
      },
    );
  }

  /// 一次性获取租约和门锁信息，单个接口失败不影响另一个。
  Future<({CurrentHome? home, LockInfo? lock})> getCurrentHomeWithLock() async {
    CurrentHome? home;
    LockInfo? lock;
    try {
      home = await getCurrentHome();
    } on Object {
      // 忽略单个接口错误
    }
    try {
      lock = await getLockInfo();
    } on Object {
      // 忽略单个接口错误
    }
    return (home: home, lock: lock);
  }

  /// 从 ApiResponse 包装中提取 data 字段并转为目标类型，data 为 null 时返回 null。
  T? _extractData<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final body = response.data;
    if (body is! Map<String, dynamic>) return null;

    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;

    return fromJson(data);
  }
}
