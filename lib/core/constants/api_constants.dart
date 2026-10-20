import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi URL dan Endpoint API aplikasi
class ApiConstants {
  ApiConstants._();

  /// Default fallback URL murni IP & Port jika .env belum dimuat
  static const String defaultUrl = 'http://192.168.100.17:8000';

  /// Mendapatkan URL server murni (IP & Port) dari .env tanpa path
  static String get serverUrl {
    final envUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['BASE_URL'];
    String raw = (envUrl != null && envUrl.trim().isNotEmpty)
        ? envUrl.trim()
        : const String.fromEnvironment('API_BASE_URL', defaultValue: defaultUrl);

    // Hapus path /api atau /api/v1 dan trailing slash jika user tidak sengaja memasukkannya
    if (raw.endsWith('/')) {
      raw = raw.substring(0, raw.length - 1);
    }
    if (raw.endsWith('/api/v1')) {
      raw = raw.substring(0, raw.length - 7);
    } else if (raw.endsWith('/api')) {
      raw = raw.substring(0, raw.length - 4);
    }

    // Pastikan memiliki skema http:// atau https://
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'http://$raw';
    }

    return raw;
  }

  /// Host server murni (misal: http://192.168.100.17:8000)
  static String get host => serverUrl;

  /// Base URL endpoint API (/api/v1)
  static String get baseUrl => '$serverUrl/api/v1';

  /// Base URL root API (/api)
  static String get apiBaseUrl => '$serverUrl/api';

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
  static const String updateProfile = '/user/profile';
  static const String forgotPasswordSendOtp = '/auth/forgot-password/send-otp';
  static const String forgotPasswordVerifyOtp = '/auth/forgot-password/verify-otp';
  static const String forgotPasswordReset = '/auth/forgot-password/reset-password';

  // Store & Master Data Endpoints
  static const String settings = '/settings';
  static const String paymentMethods = '/payment-methods';
  static const String faqs = '/faqs';

  // User Location Endpoint
  static const String userLocation = '/user/location';
}
