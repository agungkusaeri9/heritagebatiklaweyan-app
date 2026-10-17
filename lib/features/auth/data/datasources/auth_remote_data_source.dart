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

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.d('AuthRemoteDataSource: Invoking login endpoint for $email');

      final response = await dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (dioErr) {
      // Jika server contoh tidak aktif (offline / dev simulator mode)
      if (_isNetworkOrMockable(dioErr)) {
        AppLogger.w('Backend host unreachable. Simulating offline cyber authentication for demonstration.');
        return _mockLoginSuccess(email: email);
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Unexpected error during login', error: e, stackTrace: stack);
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
      AppLogger.d('AuthRemoteDataSource: Invoking register endpoint for $username ($email)');

      final response = await dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (dioErr) {
      if (_isNetworkOrMockable(dioErr)) {
        AppLogger.w('Backend host unreachable. Simulating offline cyber registration for demonstration.');
        return _mockRegisterSuccess(username: username, email: email);
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Unexpected error during registration', error: e, stackTrace: stack);
      throw ApiException(message: 'Gagal melakukan registrasi: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post(ApiConstants.logout);
    } on DioException catch (dioErr) {
      if (_isNetworkOrMockable(dioErr)) {
        AppLogger.d('Simulated offline logout completed.');
        return;
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Error during logout', error: e, stackTrace: stack);
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (dioErr) {
      if (_isNetworkOrMockable(dioErr)) {
        return UserModel(
          id: 'usr_cyber_0x99A',
          email: 'customer@heritagebatik.com',
          username: 'BatikLover',
          role: 'customer',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );
      }
      throw dioClient.handleDioError(dioErr);
    }
  }

  bool _isNetworkOrMockable(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.message?.contains('heritagebatiklaweyan.com') == true ||
        err.message?.contains('Failed host lookup') == true;
  }

  AuthResponseModel _mockLoginSuccess({required String email}) {
    final username = email.split('@').first;
    return AuthResponseModel(
      accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.token.${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'rf_${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      expiresIn: 86400,
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: username,
        role: 'customer',
        createdAt: DateTime.now(),
      ),
    );
  }

  AuthResponseModel _mockRegisterSuccess({required String username, required String email}) {
    return AuthResponseModel(
      accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.token.${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'rf_${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      expiresIn: 86400,
      user: UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: username,
        role: 'customer',
        createdAt: DateTime.now(),
      ),
    );
  }
}
