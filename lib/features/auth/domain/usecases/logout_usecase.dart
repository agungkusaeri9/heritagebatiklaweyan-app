import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Logout Akun dan Bersihkan Sesi
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<Result<void>> call() async {
    return await _repository.logout();
  }
}
