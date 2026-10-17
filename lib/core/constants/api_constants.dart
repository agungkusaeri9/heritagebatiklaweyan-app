import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Konfigurasi URL dan Endpoint API aplikasi
class ApiConstants {
  ApiConstants._();

  // Port backend Laravel lokal
  static const int port = 8000;

  static String get host {
    if (kIsWeb) {
      return 'http://127.0.0.1:$port';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://127.0.0.1:$port';
  }

  /// Base URL dinamis (/api/v1)
  static String get baseUrl => '$host/api/v1';

  /// Base URL root API (/api)
  static String get apiBaseUrl => '$host/api';

  // Timeout konfigurasi
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';

  // Store & Master Data Endpoints
  static const String settings = '/settings';
  static const String paymentMethods = '/payment-methods';
  static const String faqs = '/faqs';
}
