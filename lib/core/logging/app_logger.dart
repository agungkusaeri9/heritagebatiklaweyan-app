import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized Logger untuk seluruh aplikasi Toko Online E-Commerce
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.error,
  );

  /// Log debug (trace, state change, dev info)
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d('[DEBUG] ⚡ $message', error: error, stackTrace: stackTrace);
  }

  /// Log info (berhasil login, navigasi, transaksi, request masuk)
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('[INFO] 📦 $message', error: error, stackTrace: stackTrace);
  }

  /// Log warning (token hampir expired, cache missing, retry attempt)
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w('[WARN] ⚠️ $message', error: error, stackTrace: stackTrace);
  }

  /// Log error (koneksi putus, request 4xx/5xx, decoding error)
  static void e(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      '[ERROR] 🚨 $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Khusus untuk Network / Dio logging detail
  static void network({
    required String method,
    required String url,
    int? statusCode,
    dynamic data,
    dynamic error,
  }) {
    if (statusCode != null && statusCode >= 200 && statusCode < 300) {
      _logger.i('🌐 [NET-OK][$statusCode] $method $url\nData: $data');
    } else if (statusCode != null && statusCode >= 400) {
      _logger.e('🛑 [NET-FAIL][$statusCode] $method $url\nPayload: $data\nError: $error');
    } else {
      _logger.d('🚀 [NET-REQ] $method $url\nPayload: $data');
    }
  }
}
