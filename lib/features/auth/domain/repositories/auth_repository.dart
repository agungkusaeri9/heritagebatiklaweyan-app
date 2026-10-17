import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';

/// Abstract Contract Auth Repository (Domain Layer)
/// Bersih dari detail implementasi HTTP/Dio atau Local Storage
abstract class AuthRepository {
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> register({
    required String username,
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<UserEntity?>> getCurrentUser();

  Future<bool> isAuthenticated();
}
