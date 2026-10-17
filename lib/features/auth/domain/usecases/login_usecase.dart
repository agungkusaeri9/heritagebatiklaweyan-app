import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Login Pengguna
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) async {
    // Validasi domain bisnis sebelum memanggil repository
    if (email.trim().isEmpty) {
      return const ErrorResult(ValidationFailure(message: 'Email tidak boleh kosong'));
    }
    if (!email.contains('@')) {
      return const ErrorResult(ValidationFailure(message: 'Format email tidak valid'));
    }
    if (password.length < 6) {
      return const ErrorResult(
        ValidationFailure(message: 'Password minimal harus 6 karakter'),
      );
    }

    return await _repository.login(
      email: email.trim(),
      password: password,
    );
  }
}
