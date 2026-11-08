import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../logging/app_logger.dart';
import '../../storage/secure_storage_service.dart';
import '../session_expiry_bus.dart';

/// Interceptor untuk inject JWT Token ke Authorization header
/// dan menangani refresh token otomatis saat menerima 401 Unauthorized.
class AuthInterceptor extends QueuedInterceptor {
  final ISecureStorageService secureStorage;
  final Dio dio;

  bool _handlingSessionExpiry = false;

  AuthInterceptor({
    required this.secureStorage,
    required this.dio,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Lewati penambahan header jika endpoint adalah public (login/register)
    final isPublicEndpoint = options.path.contains(ApiConstants.login) ||
        options.path.contains(ApiConstants.register);

    if (!isPublicEndpoint) {
      final token = await secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        AppLogger.d('AuthInterceptor: Bearer token injected into header');
      }
    }

    // Default JSON headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final isPublicEndpoint = path.contains(ApiConstants.login) ||
        path.contains('/login') ||
        path.contains(ApiConstants.register) ||
        path.contains('/register');

    // Endpoint logout tidak boleh memicu alur session-expired (cegah rekursi)
    final isLogoutEndpoint = path.contains(ApiConstants.logout) ||
        path.contains('/logout');

    if (isPublicEndpoint) {
      return handler.next(err);
    }

    // Tangani token expired (401 Unauthorized)
    if (err.response?.statusCode == 401 && !isLogoutEndpoint) {
      AppLogger.w('AuthInterceptor: 401 Unauthorized detected. Attempting token refresh...');
      
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Refresh endpoint berada di balik auth:sanctum, sehingga butuh access token
          // yang sedang kedaluwarsa tetap dikirim sebagai Bearer.
          final expiredAccessToken = await secureStorage.getAccessToken();

          // Lakukan request refresh token dengan Dio instance baru agar tidak loop interceptor
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
            ),
          );

          final response = await refreshDio.post(
            ApiConstants.refreshToken,
            data: {'refresh_token': refreshToken},
            options: Options(
              headers: {
                if (expiredAccessToken != null && expiredAccessToken.isNotEmpty)
                  'Authorization': 'Bearer $expiredAccessToken',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            // Kontrak ApiResponse: { meta: {...}, data: { access_token, token_type } }
            final data = response.data;
            final payload = data is Map && data['data'] is Map ? data['data'] : data;
            final newAccessToken = payload is Map
                ? payload['access_token'] as String?
                : null;
            final newRefreshToken = payload is Map
                ? payload['refresh_token'] as String?
                : null;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await secureStorage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await secureStorage.saveRefreshToken(newRefreshToken);
              }

              AppLogger.i('AuthInterceptor: Token refreshed successfully. Retrying original request...');

              // Retry request sebelumnya dengan token baru
              final options = err.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';

              final clonedResponse = await dio.fetch(options);
              return handler.resolve(clonedResponse);
            }

            AppLogger.w('AuthInterceptor: Refresh response missing access_token. Session expired.');
            await _expireSession();
          } else {
            AppLogger.w('AuthInterceptor: Refresh token request returned ${response.statusCode}. Session expired.');
            await _expireSession();
          }
        } catch (refreshError, stack) {
          AppLogger.e(
            'AuthInterceptor: Refresh token failed. User must re-login.',
            error: refreshError,
            stackTrace: stack,
          );
          await _expireSession();
        }
      } else {
        AppLogger.w('AuthInterceptor: No refresh token available. Session expired.');
        await _expireSession();
      }
    }

    return handler.next(err);
  }

  /// Bersihkan token dan beri tahu lapisan auth agar state berubah ke unauthenticated
  /// (memicu redirect ke /login lewat router guard). Idempotent.
  Future<void> _expireSession() async {
    if (_handlingSessionExpiry) return;
    _handlingSessionExpiry = true;

    try {
      await secureStorage.clearAuthTokens();
    } catch (e, stack) {
      AppLogger.e('AuthInterceptor: Failed to clear tokens', error: e, stackTrace: stack);
    }

    try {
      SessionExpiryBus.notifyExpired();
    } catch (e, stack) {
      AppLogger.e('AuthInterceptor: session expiry notify failed', error: e, stackTrace: stack);
    } finally {
      // Izinkan sesi berikutnya (setelah login ulang) memicu expire lagi.
      _handlingSessionExpiry = false;
    }
  }
}
