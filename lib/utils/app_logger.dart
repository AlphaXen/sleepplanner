import 'package:flutter/foundation.dart';

/// Simple logger for debugging
class AppLogger {
  static const String _tag = '🔔 SleepPlanner';

  static void info(String message) {
    if (kDebugMode) {
      print('$_tag [INFO] $message');
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      print('$_tag [WARN] ⚠️  $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_tag [ERROR] ❌ $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('$_tag [DEBUG] 🐛 $message');
    }
  }
}
