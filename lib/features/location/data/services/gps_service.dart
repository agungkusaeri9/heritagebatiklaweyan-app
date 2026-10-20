import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../../core/logging/app_logger.dart';

enum GpsStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  error,
}

class GpsPositionResult {
  final GpsStatus status;
  final Position? position;
  final String message;

  const GpsPositionResult({
    required this.status,
    this.position,
    required this.message,
  });

  bool get isSuccess => status == GpsStatus.success && position != null;
}

abstract class IGpsService {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
  Future<GpsPositionResult> getCurrentPosition();
}

class GpsService implements IGpsService {
  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e, stack) {
      AppLogger.e('GpsService: Error checking isLocationServiceEnabled', error: e, stackTrace: stack);
      return false;
    }
  }

  @override
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e, stack) {
      AppLogger.e('GpsService: Error checkPermission', error: e, stackTrace: stack);
      return LocationPermission.denied;
    }
  }

  @override
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e, stack) {
      AppLogger.e('GpsService: Error requestPermission', error: e, stackTrace: stack);
      return LocationPermission.denied;
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e, stack) {
      AppLogger.e('GpsService: Error openLocationSettings', error: e, stackTrace: stack);
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e, stack) {
      AppLogger.e('GpsService: Error openAppSettings', error: e, stackTrace: stack);
      return false;
    }
  }

  @override
  Future<GpsPositionResult> getCurrentPosition() async {
    try {
      AppLogger.i('GpsService: Memeriksa ketersediaan layanan GPS perangkat...');

      // 1. Cek apakah layanan GPS aktif di perangkat
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        AppLogger.w('GpsService: Layanan GPS perangkat nonaktif.');
        return const GpsPositionResult(
          status: GpsStatus.serviceDisabled,
          message: 'Layanan lokasi (GPS) pada perangkat Anda belum diaktifkan. Silakan aktifkan GPS terlebih dahulu.',
        );
      }

      // 2. Cek izin akses lokasi saat ini
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.i('GpsService: Meminta izin lokasi ke pengguna...');
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.w('GpsService: Pengguna menolak izin lokasi.');
          return const GpsPositionResult(
            status: GpsStatus.permissionDenied,
            message: 'Izin akses lokasi ditolak. Anda tetap dapat memasukkan lokasi secara manual.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.w('GpsService: Izin lokasi ditolak secara permanen.');
        return const GpsPositionResult(
          status: GpsStatus.permissionPermanentlyDenied,
          message: 'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk memberikan izin atau gunakan input manual.',
        );
      }

      // 3. Ambil koordinat GPS perangkat secara one-shot (tanpa background polling)
      AppLogger.i('GpsService: Mengambil koordinat GPS saat ini...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      AppLogger.i('GpsService: Koordinat GPS didapatkan: Lat=${position.latitude}, Lng=${position.longitude}');
      return GpsPositionResult(
        status: GpsStatus.success,
        position: position,
        message: 'Lokasi GPS berhasil didapatkan.',
      );
    } on TimeoutException {
      AppLogger.w('GpsService: Timeout saat mengambil koordinat GPS.');
      return const GpsPositionResult(
        status: GpsStatus.timeout,
        message: 'Pengambilan lokasi GPS memakan waktu terlalu lama. Pastikan Anda berada di area dengan sinyal GPS yang baik.',
      );
    } catch (e, stack) {
      AppLogger.e('GpsService: Error mendapatkan koordinat GPS', error: e, stackTrace: stack);
      return GpsPositionResult(
        status: GpsStatus.error,
        message: 'Gagal mengambil koordinat lokasi: $e',
      );
    }
  }
}
