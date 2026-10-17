/// Base class Failure untuk Domain Layer Clean Architecture
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => '$runtimeType(message: $message, statusCode: $statusCode)';
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Terjadi kesalahan pada server.',
    super.statusCode,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Autentikasi gagal. Silakan periksa kredensial Anda.',
    super.statusCode = 401,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Input data tidak valid.',
  });
}

class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'Gagal menyimpan atau membaca data di perangkat.',
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Izin akses ditolak oleh pengguna.',
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Terjadi kesalahan tak terduga.',
  });
}
