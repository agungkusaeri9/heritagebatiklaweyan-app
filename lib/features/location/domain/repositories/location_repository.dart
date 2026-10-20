import '../../../../core/utils/result.dart';
import '../entities/user_location_entity.dart';

abstract class LocationRepository {
  /// Mengambil lokasi pengguna (dari cache dulu, kemudian sinkronisasi dengan backend jika login)
  Future<Result<UserLocationEntity?>> getUserLocation({bool forceBackendSync = false});

  /// Mengambil lokasi yang tersimpan di local cache SharedPreferences
  UserLocationEntity? getCachedLocation();

  /// Menyimpan lokasi berbasis GPS ke local cache dan sinkronisasi ke backend
  Future<Result<UserLocationEntity>> saveGpsLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? label,
  });

  /// Menyimpan lokasi manual (alamat/label) ke local cache dan sinkronisasi ke backend
  Future<Result<UserLocationEntity>> saveManualLocation({
    required String address,
    String? label,
  });

  /// Menghapus cache lokasi lokal
  Future<void> clearLocationCache();
}
