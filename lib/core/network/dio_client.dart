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
    final requestPath = error.requestOptions.path;
    final fullUri = error.requestOptions.uri.toString();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Koneksi timeout ($requestPath). Server tidak merespon dalam batas waktu.',
          details: error.message,
          uri: fullUri,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'Terjadi kesalahan pada respon server';

        if (responseData is Map<String, dynamic>) {
          final validationErrors = <String>[];

          void parseErrors(dynamic errorsObj) {
            if (errorsObj is Map) {
              for (final entry in errorsObj.values) {
                if (entry is List) {
                  validationErrors.addAll(entry.map((e) => e.toString()));
                } else if (entry is Map) {
                  parseErrors(entry);
                } else if (entry != null && entry.toString().trim().isNotEmpty) {
                  validationErrors.add(entry.toString().trim());
                }
              }
            } else if (errorsObj is List) {
              for (final entry in errorsObj) {
                if (entry != null && entry.toString().trim().isNotEmpty) {
                  validationErrors.add(entry.toString().trim());
                }
              }
            } else if (errorsObj is String && errorsObj.trim().isNotEmpty) {
              validationErrors.add(errorsObj.trim());
            }
          }

          // Prioritaskan ekstraksi dari 'errors' (Laravel standard error response)
          if (responseData['errors'] != null) {
            parseErrors(responseData['errors']);
          } else if (responseData['data'] is Map<String, dynamic> &&
              (responseData['data'] as Map<String, dynamic>)['errors'] != null) {
            parseErrors((responseData['data'] as Map<String, dynamic>)['errors']);
          }

          if (validationErrors.isNotEmpty) {
            errorMessage = validationErrors.join('\n');
          } else {
            // Jika tidak ada rincian errors, ambil pesan dari meta.message, message, atau error
            if (responseData['meta'] is Map<String, dynamic> &&
                responseData['meta']['message'] != null &&
                responseData['meta']['message'].toString().trim().isNotEmpty) {
              errorMessage = responseData['meta']['message'].toString().trim();
            } else if (responseData['message'] != null &&
                responseData['message'].toString().trim().isNotEmpty) {
              errorMessage = responseData['message'].toString().trim();
            } else if (responseData['error'] != null &&
                responseData['error'].toString().trim().isNotEmpty) {
              errorMessage = responseData['error'].toString().trim();
            }
          }
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
          case 422:
            return ApiException(
              message: errorMessage,
              statusCode: 422,
              details: responseData,
            );
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
        return NetworkException(
          message: 'Tidak dapat terhubung ke backend ($requestPath). Pastikan server aktif di ${ApiConstants.host}.',
          details: error.message,
          uri: fullUri,
        );

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
