import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import 'api_client.dart';

/// 统一管理 Dio 实例、基础配置和生命周期。
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    ),
  );

  ref.onDispose(() => dio.close(force: true));
  return dio;
});

/// 全局 ApiClient Provider，业务 Service 通过 ref.watch 注入使用。
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(dio: ref.watch(dioProvider));
});
