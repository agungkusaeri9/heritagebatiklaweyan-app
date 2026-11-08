import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/services/gps_service.dart';
import '../../domain/repositories/location_repository.dart';
import 'location_providers.dart';
import 'location_state.dart';

class LocationViewModel extends Notifier<LocationState> {
  late final LocationRepository _locationRepository;
  late final IGpsService _gpsService;

  @override
  LocationState build() {
    _locationRepository = ref.watch(locationRepositoryProvider);
    _gpsService = ref.watch(gpsServiceProvider);

    // Muat lokasi dan otomatis deteksi GPS saat aplikasi dibuka
    Future.microtask(() => initializeLocationOnAppStart());

    return const LocationState(isSyncingWithBackend: true);
  }

  /// Inisialisasi lokasi saat aplikasi dibuka: muat cache/backend & auto-refresh GPS jika izin aktif
  Future<void> initializeLocationOnAppStart() async {
    await loadLocation();
    await autoSyncGpsIfPermitted();
  }

  /// Otomatis ambil latitude & longitude serta alamat Geoapify jika izin lokasi sudah diberikan
  Future<void> autoSyncGpsIfPermitted() async {
    try {
      final isServiceEnabled = await _gpsService.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      final permission = await _gpsService.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      AppLogger.i(
        'LocationViewModel: Auto-sync GPS perangkat saat aplikasi dibuka...',
      );
      final gpsResult = await _gpsService.getCurrentPosition();
      if (!gpsResult.isSuccess || gpsResult.position == null) return;

      final pos = gpsResult.position!;
      final saveResult = await _locationRepository.saveGpsLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      saveResult.fold(
        onSuccess: (savedLocation) {
          state = state.copyWith(
            location: savedLocation,
            isSyncingWithBackend: false,
            clearError: true,
          );
          AppLogger.i(
            'LocationViewModel: Auto-sync GPS berhasil: ${savedLocation.displayName}',
          );
        },
        onFailure: (_) {},
      );
    } catch (e) {
      AppLogger.w('LocationViewModel: Gagal auto-sync GPS: $e');
    }
  }

  /// Memuat lokasi pengguna (Cache-first, lalu sinkronisasi backend)
  Future<void> loadLocation({bool forceBackendSync = false}) async {
    // 1. Muat cache lokal segera HANYA jika sudah memiliki nama alamat (bukan koordinat mentah)
    final cached = _locationRepository.getCachedLocation();
    if (cached != null && cached.hasResolvedAddress) {
      state = state.copyWith(
        location: cached,
        status: LocationStatus.initial,
        isSyncingWithBackend: true,
      );
      AppLogger.i(
        'LocationViewModel: Lokasi lokal berhasil dimuat dari cache: ${cached.displayName}',
      );
    } else {
      state = state.copyWith(isSyncingWithBackend: true);
    }

    // 2. Sinkronisasi dengan backend & resolve reverse geocoding jika masih koordinat
    final result = await _locationRepository.getUserLocation(
      forceBackendSync: forceBackendSync,
    );

    result.fold(
      onSuccess: (remoteLocation) {
        state = state.copyWith(
          location: remoteLocation ?? cached,
          isSyncingWithBackend: false,
          clearError: true,
        );
      },
      onFailure: (failure) {
        AppLogger.w(
          'LocationViewModel: Gagal sinkronisasi lokasi dengan backend: ${failure.message}',
        );
        state = state.copyWith(
          isSyncingWithBackend: false,
          // Jangan timpa lokasi jika cache sudah ada
          location: state.location ?? cached,
        );
      },
    );
  }

  /// Memilih dan mengambil lokasi GPS perangkat secara one-shot
  Future<bool> selectGpsLocation() async {
    state = state.copyWith(
      status: LocationStatus.locatingGps,
      clearError: true,
      clearSuccess: true,
      isGpsEnabled: true,
      isPermissionPermanentlyDenied: false,
    );

    // 1. Panggil service GPS perangkat
    final gpsResult = await _gpsService.getCurrentPosition();

    if (!gpsResult.isSuccess || gpsResult.position == null) {
      if (gpsResult.status == GpsStatus.serviceDisabled) {
        state = state.copyWith(
          status: LocationStatus.error,
          isGpsEnabled: false,
          errorMessage: gpsResult.message,
        );
      } else if (gpsResult.status == GpsStatus.permissionPermanentlyDenied) {
        state = state.copyWith(
          status: LocationStatus.error,
          isPermissionPermanentlyDenied: true,
          errorMessage: gpsResult.message,
        );
      } else {
        state = state.copyWith(
          status: LocationStatus.error,
          errorMessage: gpsResult.message,
        );
      }
      return false;
    }

    final pos = gpsResult.position!;

    // 2. Ambil alamat lengkap dari endpoint Geoapify backend, simpan ke local storage & sinkronkan ke backend
    state = state.copyWith(status: LocationStatus.saving);

    final saveResult = await _locationRepository.saveGpsLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    return saveResult.fold(
      onSuccess: (savedLocation) {
        state = state.copyWith(
          status: LocationStatus.success,
          location: savedLocation,
          successMessage: 'Lokasi GPS berhasil disimpan.',
          clearError: true,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: LocationStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  /// Menyimpan lokasi manual tanpa akses GPS
  Future<bool> selectManualLocation({
    required String address,
    String? label,
  }) async {
    if (address.trim().isEmpty) {
      state = state.copyWith(
        status: LocationStatus.error,
        errorMessage: 'Silakan masukkan alamat atau nama lokasi Anda.',
      );
      return false;
    }

    state = state.copyWith(
      status: LocationStatus.saving,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _locationRepository.saveManualLocation(
      address: address.trim(),
      label: label?.trim().isNotEmpty == true ? label!.trim() : 'Lokasi Manual',
    );

    return result.fold(
      onSuccess: (savedLocation) {
        state = state.copyWith(
          status: LocationStatus.success,
          location: savedLocation,
          successMessage: 'Lokasi manual berhasil disimpan.',
          clearError: true,
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: LocationStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }

  /// Buka menu pengaturan lokasi perangkat jika GPS nonaktif
  Future<void> openLocationSettings() async {
    await _gpsService.openLocationSettings();
  }

  /// Buka menu pengaturan aplikasi jika izin ditolak permanen
  Future<void> openAppSettings() async {
    await _gpsService.openAppSettings();
  }

  /// Bersihkan pesan feedback error/success
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
