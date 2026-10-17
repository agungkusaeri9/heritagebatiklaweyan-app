/// Custom Exceptions untuk penanganan error di Data Layer (Dio, Storage, dll)
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Koneksi internet bermasalah. Periksa jaringan Anda.',
    super.statusCode,
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Sesi telah berakhir atau kredensial tidak valid. Silakan login kembali.',
    super.statusCode = 401,
  });
}

class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Akses ditolak. Anda tidak memiliki izin untuk resource ini.',
    super.statusCode = 403,
  });
}

class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Resource tidak ditemukan di server.',
    super.statusCode = 404,
  });
}

class ServerException extends ApiException {
  const ServerException({
    super.message = 'Terjadi kesalahan internal pada server.',
    super.statusCode = 500,
  });
}

class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Permintaan melebihi batas waktu (Timeout). Coba lagi beberapa saat lagi.',
  });
}

class StorageException implements Exception {
  final String message;
  const StorageException([this.message = 'Gagal mengakses local storage']);

  @override
  String toString() => 'StorageException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Gagal membaca atau menyimpan cache']);

  @override
  String toString() => 'CacheException: $message';
}
