import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/router/app_router.dart';
import 'core/network/api_interceptor.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize();
  await StorageService.initialize();

  // 注册统一 Token 过期回调：清空本地会话后跳转登录页
  ApiInterceptor.onForceLogout = () async {
    AppRouter.router.go('/login');
  };

  runApp(const ProviderScope(child: ZhuxiangApp()));
}
