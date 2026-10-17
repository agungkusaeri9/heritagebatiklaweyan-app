import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../storage/storage_providers.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Provider Dio Client instance terkonfigurasi
final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );

  // Pasang interceptors
  dio.interceptors.addAll([
    AuthInterceptor(secureStorage: secureStorage, dio: dio),
    LoggingInterceptor(),
  ]);

  return dio;
});

/// Wrapper DioClient untuk standardisasi HTTP calls dan error mapping
class DioClient {
  final Dio _dio;

  DioClient(this._dio);

  Dio get dio => _dio;

  /// Helper untuk menangani DioException ke Typed ApiException
  ApiException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'Terjadi kesalahan pada respon server';

        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ??
              responseData['error'] ??
              errorMessage;
        }

        switch (statusCode) {
          case 400:
            return ApiException(
              message: errorMessage,
              statusCode: 400,
              details: responseData,
            );
          case 401:
            return UnauthorizedException(message: errorMessage);
          case 403:
            return ForbiddenException(message: errorMessage);
          case 404:
            return NotFoundException(message: errorMessage);
          case 500:
          case 502:
          case 503:
            return ServerException(message: errorMessage, statusCode: statusCode);
          default:
            return ApiException(
              message: errorMessage,
              statusCode: statusCode,
              details: responseData,
            );
        }

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.cancel:
        return const ApiException(message: 'Permintaan dibatalkan.');

      case DioExceptionType.badCertificate:
        return const ApiException(message: 'Sertifikat SSL server tidak valid.');

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: error.message ?? 'Terjadi kesalahan tak terduga.',
          details: error.error,
        );
    }
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioClient(dio);
});
