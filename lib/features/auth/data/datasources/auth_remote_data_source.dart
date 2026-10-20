import 'dart:io';
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

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String gender,
    String? avatar,
    String? avatarFilePath,
  });

  Future<String> sendPasswordResetOtp({required String email});

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  });
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

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String gender,
    String? avatar,
    String? avatarFilePath,
  }) async {
    try {
      AppLogger.i(
        'AuthRemoteDataSource: Memperbarui profil: $name, $phone, $gender, avatarFile: $avatarFilePath',
      );

      dynamic requestData;
      if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
        final fileName = avatarFilePath.split(Platform.pathSeparator).last;
        final formData = FormData.fromMap({
          'name': name.trim(),
          'phone': phone.trim(),
          'gender': gender.trim(),
          'avatar': await MultipartFile.fromFile(
            avatarFilePath,
            filename: fileName,
          ),
          '_method': 'PUT',
        });
        requestData = formData;
      } else {
        requestData = <String, dynamic>{
          'name': name.trim(),
          'phone': phone.trim(),
          'gender': gender.trim(),
          if (avatar != null) 'avatar': avatar.trim(),
        };
      }

      Response? response;
      final candidateEndpoints = [
        ApiConstants.updateProfile,
        '/user/profile',
        '/profile',
        '${ApiConstants.apiBaseUrl}/user/profile',
      ];

      DioException? lastDioError;
      for (final endpoint in candidateEndpoints) {
        try {
          if (requestData is FormData) {
            AppLogger.d('AuthRemoteDataSource: Trying POST multipart $endpoint');
            response = await dio.post(endpoint, data: requestData);
          } else {
            AppLogger.d('AuthRemoteDataSource: Trying PUT $endpoint');
            response = await dio.put(endpoint, data: requestData);
          }
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            break;
          }
        } on DioException catch (e) {
          lastDioError = e;
          if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
            try {
              AppLogger.d('AuthRemoteDataSource: Trying fallback POST $endpoint');
              response = await dio.post(endpoint, data: requestData);
              if (response.statusCode != null &&
                  response.statusCode! >= 200 &&
                  response.statusCode! < 300) {
                break;
              }
            } catch (_) {
              // lanjut ke endpoint berikutnya
            }
            continue;
          }
          throw dioClient.handleDioError(e);
        }
      }

      if (response != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        final userRaw = responseData['data'] ?? responseData['user'] ?? responseData;
        if (userRaw is Map<String, dynamic>) {
          return UserModel.fromJson(userRaw);
        }
      }

      if (lastDioError != null) {
        throw dioClient.handleDioError(lastDioError);
      }

      throw const ApiException(message: 'Format respon pembaruan profil tidak valid.');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error updating profile', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memperbarui profil: $e');
    }
  }

  @override
  Future<String> sendPasswordResetOtp({required String email}) async {
    try {
      AppLogger.i('AuthRemoteDataSource: Mengirim OTP reset password ke $email');
      final candidateEndpoints = [
        ApiConstants.forgotPasswordSendOtp,
        '/auth/forgot-password/send-otp',
        '/forgot-password/send-otp',
        '${ApiConstants.apiBaseUrl}/auth/forgot-password/send-otp',
      ];

      final payload = {'email': email.trim()};
      final response = await _postWithFallback(candidateEndpoints, payload);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return data['message']?.toString() ??
            'Kode OTP pemulihan kata sandi telah dikirim ke email Anda.';
      }
      return 'Kode OTP pemulihan kata sandi telah dikirim ke email Anda.';
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error sending password reset OTP', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengirim kode OTP: $e');
    }
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      AppLogger.i('AuthRemoteDataSource: Memverifikasi OTP untuk $email');
      final candidateEndpoints = [
        ApiConstants.forgotPasswordVerifyOtp,
        '/auth/forgot-password/verify-otp',
        '/forgot-password/verify-otp',
        '${ApiConstants.apiBaseUrl}/auth/forgot-password/verify-otp',
      ];

      final payload = {
        'email': email.trim(),
        'otp': otp.trim(),
      };
      final response = await _postWithFallback(candidateEndpoints, payload);

      if (response.data is Map) {
        final data = response.data as Map;
        final innerData = data['data'];
        if (innerData is Map) {
          final token = innerData['reset_token'] ??
              innerData['resetToken'] ??
              innerData['token'];
          if (token != null && token.toString().trim().isNotEmpty) {
            return token.toString().trim();
          }
        }
        final token = data['reset_token'] ??
            data['resetToken'] ??
            data['token'];
        if (token != null && token.toString().trim().isNotEmpty) {
          return token.toString().trim();
        }
      }
      throw const ApiException(message: 'Respon token pemulihan dari server tidak valid.');
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error verifying OTP', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memverifikasi OTP: $e');
    }
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      AppLogger.i('AuthRemoteDataSource: Mengatur ulang kata sandi untuk $email');
      final candidateEndpoints = [
        ApiConstants.forgotPasswordReset,
        '/auth/forgot-password/reset-password',
        '/auth/reset-password',
        '/reset-password',
        '${ApiConstants.apiBaseUrl}/auth/forgot-password/reset-password',
      ];

      final payload = {
        'email': email.trim(),
        'reset_token': resetToken.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
      final response = await _postWithFallback(candidateEndpoints, payload);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        return data['message']?.toString() ??
            'Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru Anda.';
      }
      return 'Kata sandi berhasil diperbarui.';
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error resetting password', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mereset kata sandi: $e');
    }
  }
}
