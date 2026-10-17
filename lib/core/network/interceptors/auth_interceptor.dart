import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../logging/app_logger.dart';
import '../../storage/secure_storage_service.dart';

/// Interceptor untuk inject JWT Token ke Authorization header
/// dan menangani refresh token otomatis saat menerima 401 Unauthorized.
class AuthInterceptor extends QueuedInterceptor {
  final ISecureStorageService secureStorage;
  final Dio dio;

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
    // Tangani token expired (401 Unauthorized)
    if (err.response?.statusCode == 401) {
      AppLogger.w('AuthInterceptor: 401 Unauthorized detected. Attempting token refresh...');
      
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
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
          );

          if (response.statusCode == 200 && response.data != null) {
            final newAccessToken = response.data['access_token'] as String?;
            final newRefreshToken = response.data['refresh_token'] as String?;

            if (newAccessToken != null) {
              await secureStorage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null) {
                await secureStorage.saveRefreshToken(newRefreshToken);
              }

              AppLogger.i('AuthInterceptor: Token refreshed successfully. Retrying original request...');

              // Retry request sebelumnya dengan token baru
              final options = err.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';
              
              final clonedResponse = await dio.fetch(options);
              return handler.resolve(clonedResponse);
            }
          }
        } catch (refreshError, stack) {
          AppLogger.e(
            'AuthInterceptor: Refresh token failed. User must re-login.',
            error: refreshError,
            stackTrace: stack,
          );
          // Hapus token kadaluarsa
          await secureStorage.clearAuthTokens();
        }
      } else {
        AppLogger.w('AuthInterceptor: No refresh token available. Session expired.');
        await secureStorage.clearAuthTokens();
      }
    }

    return handler.next(err);
  }
}
