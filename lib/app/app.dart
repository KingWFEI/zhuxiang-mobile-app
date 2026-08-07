import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/message/data/providers/message_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class ZhuxiangApp extends ConsumerWidget {
  const ZhuxiangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(messageRealtimeCoordinatorProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '勿忧管家',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
