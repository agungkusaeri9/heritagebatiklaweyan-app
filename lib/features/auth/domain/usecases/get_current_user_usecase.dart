import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Mengambil data pengguna yang sedang login saat ini
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<Result<UserEntity?>> call() async {
    return await _repository.getCurrentUser();
  }
}
