import 'dart:convert';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/user_location_model.dart';

abstract class ILocationLocalDataSource {
  UserLocationModel? getCachedLocation();
  Future<void> cacheLocation(UserLocationModel location);
  Future<void> clearCachedLocation();
}

class LocationLocalDataSource implements ILocationLocalDataSource {
  final ILocalStorageService _storage;

  LocationLocalDataSource(this._storage);

  @override
  UserLocationModel? getCachedLocation() {
    try {
      final raw = _storage.getString(StorageKeys.cachedUserLocation);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserLocationModel.fromJson(decoded);
      }
      if (decoded is Map) {
        return UserLocationModel.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (e, stack) {
      AppLogger.e('LocationLocalDataSource: Error reading cached location', error: e, stackTrace: stack);
      return null;
    }
  }

  @override
  Future<void> cacheLocation(UserLocationModel location) async {
    try {
      final raw = jsonEncode(location.toJson());
      await _storage.setString(StorageKeys.cachedUserLocation, raw);
      AppLogger.i('LocationLocalDataSource: Lokasi berhasil disimpan di local cache.');
    } catch (e, stack) {
      AppLogger.e('LocationLocalDataSource: Error saving cached location', error: e, stackTrace: stack);
    }
  }

  @override
  Future<void> clearCachedLocation() async {
    try {
      await _storage.remove(StorageKeys.cachedUserLocation);
      AppLogger.i('LocationLocalDataSource: Cache lokasi dihapus.');
    } catch (e, stack) {
      AppLogger.e('LocationLocalDataSource: Error clearing cached location', error: e, stackTrace: stack);
    }
  }
}
