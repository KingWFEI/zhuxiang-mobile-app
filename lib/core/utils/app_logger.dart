import 'package:flutter/foundation.dart';

class AppLoggerDebug {
  static const String _reset = '\x1B[0m';

  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';

  /// 普通信息日志
  static void info(String message) {
    debugPrint('$_blue[INFO] $message$_reset');
  }

  /// 成功日志
  static void success(String message) {
    debugPrint('$_green[SUCCESS] $message$_reset');
  }

  /// 警告日志
  static void warning(String message) {
    debugPrint('$_yellow[WARNING] $message$_reset');
  }

  /// 错误日志
  static void error(String message) {
    debugPrint('$_red[ERROR] $message$_reset');
  }

  /// 蓝牙 / 门锁相关日志
  static void lock(String message) {
    debugPrint('$_cyan[TTLOCK] $message$_reset');
  }
}
