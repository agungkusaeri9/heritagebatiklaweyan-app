import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/user_location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_data_source.dart';
import '../datasources/location_remote_data_source.dart';
import '../models/user_location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final ILocationLocalDataSource localDataSource;
  final ILocationRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;

  LocationRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  });

  @override
  UserLocationEntity? getCachedLocation() {
    return localDataSource.getCachedLocation()?.toEntity();
  }

  Future<UserLocationModel> _resolveAddressIfNeeded(
    UserLocationModel model,
  ) async {
    if (model.latitude == null || model.longitude == null) {
      return model;
    }

    final addr = model.address?.trim() ?? '';
    final lbl = model.label?.trim() ?? '';
    final needsReverseGeocode =
    UserLocationEntity.isPlaceholderOrCoordinate(addr) ||
        UserLocationEntity.isPlaceholderOrCoordinate(lbl);

    if (!needsReverseGeocode) {
      return model;
    }

    final resolvedAddress = await remoteDataSource.getAddressFromCoordinates(
      latitude: model.latitude!,
      longitude: model.longitude!,
    );

    if (resolvedAddress != null && resolvedAddress.isNotEmpty) {
      return UserLocationModel(
        id: model.id,
        source: model.source,
        latitude: model.latitude,
        longitude: model.longitude,
        address: resolvedAddress,
        label: resolvedAddress,
        updatedAt: model.updatedAt ?? DateTime.now(),
      );
    }

    return model;
  }

  @override
  Future<Result<UserLocationEntity?>> getUserLocation({
    bool forceBackendSync = false,
  }) async {
    try {
      var cachedModel = localDataSource.getCachedLocation();
      if (cachedModel != null) {
        final resolvedCached = await _resolveAddressIfNeeded(cachedModel);
        if (resolvedCached.address != cachedModel.address ||
            resolvedCached.label != cachedModel.label) {
          cachedModel = resolvedCached;
          await localDataSource.cacheLocation(cachedModel);
        }
      }

      final isAuthenticated = await authRepository.isAuthenticated();

      // Jika belum login, gunakan cache lokal saja
      if (!isAuthenticated) {
        AppLogger.i(
          'LocationRepository: Pengguna guest/belum login, memuat lokasi dari cache lokal.',
        );
        return Success(cachedModel?.toEntity());
      }

      // Jika login, gunakan backend sebagai sumber data utama
      try {
        AppLogger.i(
          'LocationRepository: Mengambil lokasi pengguna dari backend...',
        );
        var remoteModel = await remoteDataSource.getUserLocation();

        if (remoteModel != null) {
          remoteModel = await _resolveAddressIfNeeded(remoteModel);
          // Perbarui cache lokal dengan data backend terbaru
          await localDataSource.cacheLocation(remoteModel);
          return Success(remoteModel.toEntity());
        } else if (cachedModel != null) {
          // Jika di backend belum ada tetapi di cache ada, sinkronkan cache lokal ke backend
          try {
            final syncedModel = await remoteDataSource.updateUserLocation(
              cachedModel,
            );
            await localDataSource.cacheLocation(syncedModel);
            return Success(syncedModel.toEntity());
          } catch (_) {
            return Success(cachedModel.toEntity());
          }
        }

        return const Success(null);
      } on NetworkException catch (e) {
        AppLogger.w(
          'LocationRepository: Gangguan jaringan saat sinkronisasi lokasi backend: ${e.message}',
        );
        // Fallback ke cache lokal tanpa membuat aplikasi crash
        return Success(cachedModel?.toEntity());
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          return Success(cachedModel?.toEntity());
        }
        AppLogger.w(
          'LocationRepository: Server API exception saat memuat lokasi: ${e.message}',
        );
        return Success(cachedModel?.toEntity());
      }
    } catch (e, stack) {
      AppLogger.e(
        'LocationRepository: Unexpected error getting user location',
        error: e,
        stackTrace: stack,
      );
      final cached = localDataSource.getCachedLocation();
      return Success(cached?.toEntity());
    }
  }

  @override
  Future<Result<UserLocationEntity>> saveGpsLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? label,
  }) async {
    try {
      String? resolvedAddress = address?.trim();
      if (resolvedAddress == null ||
          resolvedAddress.isEmpty ||
          resolvedAddress.toLowerCase().startsWith('koordinat')) {
        resolvedAddress = await remoteDataSource.getAddressFromCoordinates(
          latitude: latitude,
          longitude: longitude,
        );
      }

      final finalAddress =
          (resolvedAddress != null && resolvedAddress.isNotEmpty)
          ? resolvedAddress
          : '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

      String finalLabel =
          (label != null &&
              label.trim().isNotEmpty &&
              label.trim().toLowerCase() != 'lokasi perangkat (gps)' &&
              label.trim().toLowerCase() != 'lokasi saat ini')
          ? label.trim()
          : finalAddress;

      if (finalLabel.length > 90) {
        finalLabel = finalLabel.substring(0, 90).trim();
      }

      final model = UserLocationModel(
        source: 'gps',
        latitude: latitude,
        longitude: longitude,
        address: finalAddress,
        label: finalLabel,
        updatedAt: DateTime.now(),
      );

      final isAuthenticated = await authRepository.isAuthenticated();

      if (isAuthenticated) {
        // Sinkronisasi ke backend
        AppLogger.i(
          'LocationRepository: Menyinkronkan lokasi GPS ke backend...',
        );
        final savedRemote = await remoteDataSource.updateUserLocation(model);
        await localDataSource.cacheLocation(savedRemote);
        return Success(savedRemote.toEntity());
      } else {
        // Simpan ke local cache untuk guest
        await localDataSource.cacheLocation(model);
        return Success(model.toEntity());
      }
    } on NetworkException catch (e) {
      AppLogger.w(
        'LocationRepository: Jaringan gagal saat simpan GPS: ${e.message}',
      );
      return ErrorResult(NetworkFailure(message: e.message));
    } on ApiException catch (e) {
      AppLogger.e('LocationRepository: API error saat simpan GPS', error: e);
      return ErrorResult(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e, stack) {
      AppLogger.e(
        'LocationRepository: Error saving GPS location',
        error: e,
        stackTrace: stack,
      );
      return ErrorResult(
        UnknownFailure(message: 'Gagal menyimpan lokasi GPS: $e'),
      );
    }
  }

  @override
  Future<Result<UserLocationEntity>> saveManualLocation({
    required String address,
    String? label,
  }) async {
    try {
      if (address.trim().isEmpty) {
        return const ErrorResult(
          ValidationFailure(message: 'Alamat lokasi tidak boleh kosong.'),
        );
      }

      String finalLabel = label?.trim().isNotEmpty == true
          ? label!.trim()
          : 'Lokasi Manual';
      if (finalLabel.length > 90) {
        finalLabel = finalLabel.substring(0, 90).trim();
      }

      final model = UserLocationModel(
        source: 'manual',
        latitude: null,
        longitude: null,
        address: address.trim(),
        label: finalLabel,
        updatedAt: DateTime.now(),
      );

      final isAuthenticated = await authRepository.isAuthenticated();

      if (isAuthenticated) {
        AppLogger.i(
          'LocationRepository: Menyinkronkan lokasi manual ke backend...',
        );
        final savedRemote = await remoteDataSource.updateUserLocation(model);
        await localDataSource.cacheLocation(savedRemote);
        return Success(savedRemote.toEntity());
      } else {
        await localDataSource.cacheLocation(model);
        return Success(model.toEntity());
      }
    } on NetworkException catch (e) {
      AppLogger.w(
        'LocationRepository: Jaringan gagal saat simpan lokasi manual: ${e.message}',
      );
      return ErrorResult(NetworkFailure(message: e.message));
    } on ApiException catch (e) {
      AppLogger.e(
        'LocationRepository: API error saat simpan lokasi manual',
        error: e,
      );
      return ErrorResult(
        ServerFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e, stack) {
      AppLogger.e(
        'LocationRepository: Error saving manual location',
        error: e,
        stackTrace: stack,
      );
      return ErrorResult(
        UnknownFailure(message: 'Gagal menyimpan lokasi manual: $e'),
      );
    }
  }

  @override
  Future<void> clearLocationCache() async {
    await localDataSource.clearCachedLocation();
  }
}
