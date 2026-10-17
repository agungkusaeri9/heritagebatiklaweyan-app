import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.dioClient,
  });

  /// Helper untuk mencoba request POST ke beberapa kemungkinan endpoint (misal /auth/login, /login)
  Future<Response> _postWithFallback(
    List<String> endpoints,
    Map<String, dynamic> data,
  ) async {
    DioException? lastError;

    for (final endpoint in endpoints) {
      try {
        AppLogger.d('AuthRemoteDataSource: Trying POST $endpoint');
        final response = await dio.post(endpoint, data: data);
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return response;
        }
      } on DioException catch (e) {
        lastError = e;
        // Jika 404 (Route not found), lanjut coba endpoint kandidat berikutnya
        if (e.response?.statusCode == 404) {
          AppLogger.w('Endpoint $endpoint returned 404 Not Found, trying next candidate...');
          continue;
        }
        // Jika error validasi atau kredensial (401, 422, 500), lempar error asli dari backend
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw const ApiException(message: 'Semua kandidat endpoint backend tidak merespon.');
  }

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('AuthRemoteDataSource: Melakukan login backend untuk email: $email');

      // Kandidat endpoint login backend Laravel
      final candidateEndpoints = [
        ApiConstants.login, // /auth/login (relatif ke /api/v1)
        '/login',           // /login (relatif ke /api/v1)
        '${ApiConstants.apiBaseUrl}/login',      // /api/login (tanpa v1)
        '${ApiConstants.apiBaseUrl}/auth/login', // /api/auth/login (tanpa v1)
      ];

      final payload = {
        'email': email,
        'password': password,
      };

      final response = await _postWithFallback(candidateEndpoints, payload);

      if (response.data is Map<String, dynamic>) {
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(message: 'Format respon login dari backend tidak valid');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Unexpected error during login', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal melakukan login: $e');
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('AuthRemoteDataSource: Melakukan registrasi backend untuk $username ($email)');

      // Kandidat endpoint register backend Laravel
      final candidateEndpoints = [
        ApiConstants.register, // /auth/register (relatif ke /api/v1)
        '/register',           // /register (relatif ke /api/v1)
        '${ApiConstants.apiBaseUrl}/register',      // /api/register (tanpa v1)
        '${ApiConstants.apiBaseUrl}/auth/register', // /api/auth/register (tanpa v1)
      ];

      // Sanitasi username untuk memenuhi aturan Laravel alpha_dash (hanya huruf, angka, dash, dan underscore tanpa spasi)
      String cleanUsername = username
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
      if (cleanUsername.isEmpty) {
        cleanUsername = email.split('@').first.replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
      }

      // Kirim name, username, email, password, dan password_confirmation untuk kompatibilitas penuh dengan Laravel controller
      final payload = {
        'name': username.trim(),
        'username': cleanUsername,
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
      };

      final response = await _postWithFallback(candidateEndpoints, payload);

      if (response.data is Map<String, dynamic>) {
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(message: 'Format respon registrasi dari backend tidak valid');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Unexpected error during registration', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal melakukan registrasi: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        try {
          await dio.post('/logout');
          return;
        } catch (_) {}
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error during logout', error: e, stackTrace: stack);
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      Response response;
      try {
        response = await dio.get(ApiConstants.profile);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          response = await dio.get('/me');
        } else {
          rethrow;
        }
      }

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final userRaw = responseData['data'] ?? responseData['user'] ?? responseData;
        if (userRaw is Map<String, dynamic>) {
          return UserModel.fromJson(userRaw);
        }
      }
      throw const ApiException(message: 'Format profil pengguna tidak sesuai');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error getting profile', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal mengambil profil: $e');
    }
  }
}
