import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/storage/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  AppConfig.initialize();
  await StorageService.initialize();

  runApp(const ProviderScope(child: ZhuxiangApp()));
}
