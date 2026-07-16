import 'app_env.dart';

class AppConfig {
  const AppConfig._();

  static AppEnv currentEnv = AppEnv.dev;

  static void initialize({AppEnv env = AppEnv.dev}) {
    currentEnv = env;
  }

  static String get appName => '住享';

  static String get baseUrl {
    return switch (currentEnv) {
      // AppEnv.dev => 'http://10.143.183.109:8000/api',
      AppEnv.dev => 'http://10.20.70.232:8000/api',
      AppEnv.staging => 'https://staging.example.com/api',
      AppEnv.prod => 'https://api.example.com/api',
    };
  }

  static Duration get connectTimeout => const Duration(seconds: 15);

  static Duration get receiveTimeout => const Duration(seconds: 15);
}
