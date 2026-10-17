import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Simpan Access Token & Refresh Token di Secure Storage (Hardware Enkripsi)
      await localDataSource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Simpan User Cache & Last Username di Local Storage non-sensitif
      await localDataSource.cacheUser(response.user);
      await localDataSource.saveLastUsername(response.user.username);

      AppLogger.i('AuthRepository: User ${response.user.username} successfully authenticated');
      return Success(response.user.toEntity());
    } on UnauthorizedException catch (e) {
      return ErrorResult(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return ErrorResult(NetworkFailure(message: e.message));
    } on ApiException catch (e) {
      return ErrorResult(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stack) {
      AppLogger.e('AuthRepository login unexpected error', error: e, stackTrace: stack);
      return ErrorResult(UnknownFailure(message: 'Login gagal: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.register(
        username: username,
        email: email,
        password: password,
      );

      // Simpan token & user
      await localDataSource.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await localDataSource.cacheUser(response.user);
      await localDataSource.saveLastUsername(response.user.username);

      AppLogger.i('AuthRepository: User $username registered successfully');
      return Success(response.user.toEntity());
    } on NetworkException catch (e) {
      return ErrorResult(NetworkFailure(message: e.message));
    } on ApiException catch (e) {
      return ErrorResult(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stack) {
      AppLogger.e('AuthRepository register unexpected error', error: e, stackTrace: stack);
      return ErrorResult(UnknownFailure(message: 'Registrasi gagal: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      AppLogger.w('Remote logout failed, proceeding with local cache purge: $e');
    } finally {
      await localDataSource.clearAuthData();
    }
    return const Success(null);
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      // Coba ambil dari local cache terlebih dahulu
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Success(cachedUser.toEntity());
      }

      // Jika belum ada, coba fetch profile dari API jika ada token
      final token = await localDataSource.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final remoteUser = await remoteDataSource.getProfile();
        await localDataSource.cacheUser(remoteUser);
        return Success(remoteUser.toEntity());
      }

      return const Success(null);
    } catch (e, stack) {
      AppLogger.e('Failed to get current user', error: e, stackTrace: stack);
      return const Success(null);
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await localDataSource.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
