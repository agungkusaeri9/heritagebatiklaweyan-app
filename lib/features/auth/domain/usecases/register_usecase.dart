import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Registrasi Akun Baru
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String username,
    required String email,
    required String password,
  }) async {
    // Validasi domain bisnis
    if (username.trim().length < 3) {
      return const ErrorResult(
        ValidationFailure(message: 'Username minimal 3 karakter'),
      );
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      return const ErrorResult(
        ValidationFailure(message: 'Alamat email tidak valid'),
      );
    }
    if (password.length < 6) {
      return const ErrorResult(
        ValidationFailure(message: 'Password minimal 6 karakter'),
      );
    }

    return await _repository.register(
      username: username.trim(),
      email: email.trim(),
      password: password,
    );
  }
}
