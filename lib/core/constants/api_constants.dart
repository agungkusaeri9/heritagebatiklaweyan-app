import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi URL dan Endpoint API aplikasi
class ApiConstants {
  ApiConstants._();

  /// Default fallback URL murni IP & Port jika .env belum dimuat
  static const String defaultUrl = 'http://192.168.1.12:8000';

  /// Mendapatkan URL server murni (IP & Port) dari .env tanpa path
  static String get serverUrl {
    final envUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['BASE_URL'];
    String raw = (envUrl != null && envUrl.trim().isNotEmpty)
        ? envUrl.trim()
        : const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: defaultUrl,
          );

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
  static const String forgotPasswordVerifyOtp =
      '/auth/forgot-password/verify-otp';
  static const String forgotPasswordReset =
      '/auth/forgot-password/reset-password';
  static const String sendEmailVerificationOtp = '/auth/email/send-otp';
  static const String verifyEmailVerificationOtp = '/auth/email/verify-otp';
  static const String resendEmailVerificationOtp = '/auth/email/resend-otp';

  // Store & Master Data Endpoints
  static const String ping = '/ping';
  static const String settings = '/settings';
  static const String privacyPolicy = '/settings/privacy-policy';
  static const String stores = '/stores';
  static String storeDetail(int id) => '/stores/$id';
  static const String paymentMethods = '/payment-methods';
  static const String faqs = '/faqs';
  static const String categories = '/categories';
  static const String banners = '/banners';
  static const String products = '/products';
  static const String productRecommendations = '/products/recommendations';
  static const String productBestSellers = '/products/best-sellers';
  static String productDetail(dynamic idOrSlug) => '/products/$idOrSlug';

  // User Location & Addresses Endpoints
  static const String userLocation = '/user/location';
  static const String addresses = '/addresses';
  static String addressDetail(int id) => '/addresses/$id';
  static String addressPrimary(int id) => '/addresses/$id/primary';

  // Master Location Endpoints
  static String getAddress({required double lat, required double lon}) =>
      '/locations/address?lat=$lat&lon=$lon';
  static const String provinces = '/locations/provinces';
  static String cities({int? provinceId}) => provinceId != null
      ? '/locations/cities?province_id=$provinceId'
      : '/locations/cities';
  static String subdistricts({int? cityId}) => cityId != null
      ? '/locations/subdistricts?city_id=$cityId'
      : '/locations/subdistricts';

  // Shipping & Couriers Endpoints
  static const String couriers = '/couriers';
  static const String shippingTypes = '/shipping-types';
  static const String checkShippingCost = '/shipping/cost';
  static const String checkOngkir = '/check-ongkir';

  // Notifications Endpoints
  static const String notifications = '/notifications';
  static const String notificationsMarkRead = '/notifications/mark-read';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
  static String notificationMarkSingleRead(int id) =>
      '/notifications/$id/mark-read';

  // Cart Endpoints
  static const String cart = '/cart';
  static String cartItem(int id) => '/cart/$id';

  // Wishlist Endpoints
  static const String wishlist = '/wishlist';
  static String wishlistItem(int productId) => '/wishlist/$productId';

  // Checkout Endpoints
  static const String checkout = '/checkout';
  static const String checkoutPreview = '/checkout/preview';

  // Orders & Reviews Endpoints
  static const String orders = '/orders';
  static String orderDetail(dynamic idOrOrderNumber) =>
      '/orders/$idOrOrderNumber';
  static String uploadPaymentProof(dynamic idOrOrderNumber) =>
      '/orders/$idOrOrderNumber/payment-proof';
  static const String reviews = '/reviews';
  static String productReviews(dynamic idOrSlug) =>
      '/products/$idOrSlug/reviews';

  // Virtual Try-On Endpoints
  static const String virtualTryOns = '/virtual-try-ons';
  static const String virtualTryOnModels = '/virtual-try-ons/models';
  static String productVirtualTryOns(int productId) =>
      '/products/$productId/virtual-try-ons';
  static String virtualTryOnDetail(int id) => '/virtual-try-ons/$id';
  static String virtualTryOnProgress(int id) => '/virtual-try-ons/$id/progress';
  static String virtualTryOnRetry(int id) => '/virtual-try-ons/$id/retry';
}
