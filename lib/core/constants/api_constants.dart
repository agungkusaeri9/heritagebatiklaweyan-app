/// Konfigurasi URL dan Endpoint API aplikasi
class ApiConstants {
  ApiConstants._();

  // Ubah Base URL sesuai environment backend toko online (Dev / Staging / Prod)
  static const String baseUrl = 'https://api.heritagebatiklaweyan.com/api/v1';

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
}
