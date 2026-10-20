import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../logging/app_logger.dart';

/// Enum tipe izin yang didukung aplikasi
enum AppPermissionType {
  camera,
  gallery,
  location,
  notification,
}

/// Model hasil pengecekan atau permintaan izin
class PermissionResult {
  final AppPermissionType type;
  final PermissionStatus status;
  final String message;

  const PermissionResult({
    required this.type,
    required this.status,
    required this.message,
  });

  bool get isGranted => status.isGranted || status.isLimited;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
  bool get isDenied => status.isDenied;
  bool get isRestricted => status.isRestricted;
}

/// Kontrak service izin perangkat
abstract class IPermissionService {
  Future<PermissionResult> checkPermission(AppPermissionType type);
  Future<PermissionResult> requestPermission(AppPermissionType type);
  Future<Map<AppPermissionType, PermissionResult>> requestMultiple(
    List<AppPermissionType> types,
  );
  Future<bool> openSettings();
}

class PermissionService implements IPermissionService {
  Permission _mapTypeToPermission(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.camera:
        return Permission.camera;

      case AppPermissionType.gallery:
        // Android 13+ (API 33+) menggunakan READ_MEDIA_IMAGES (photos)
        // iOS menggunakan photos
        // Android versi lama menggunakan storage
        if (!kIsWeb && Platform.isAndroid) {
          return Permission.photos;
        }
        return Permission.photos;

      case AppPermissionType.location:
        return Permission.locationWhenInUse;

      case AppPermissionType.notification:
        return Permission.notification;
    }
  }

  String _getPermissionName(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.camera:
        return 'Kamera';
      case AppPermissionType.gallery:
        return 'Galeri Foto & Media';
      case AppPermissionType.location:
        return 'Lokasi GPS';
      case AppPermissionType.notification:
        return 'Notifikasi Sistem';
    }
  }

  @override
  Future<PermissionResult> checkPermission(AppPermissionType type) async {
    try {
      if (type == AppPermissionType.gallery && !kIsWeb && Platform.isAndroid) {
        final photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted || photosStatus.isLimited) {
          return PermissionResult(
            type: type,
            status: photosStatus,
            message: 'Status izin Galeri: ${photosStatus.name}',
          );
        }
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return PermissionResult(
            type: type,
            status: storageStatus,
            message: 'Status izin Galeri: ${storageStatus.name}',
          );
        }
        final statusToReport =
            photosStatus.isPermanentlyDenied ? photosStatus : storageStatus;
        return PermissionResult(
          type: type,
          status: statusToReport,
          message: 'Status izin Galeri: ${statusToReport.name}',
        );
      }

      final permission = _mapTypeToPermission(type);
      final status = await permission.status;
      AppLogger.d('Permission check: ${_getPermissionName(type)} -> $status');

      return PermissionResult(
        type: type,
        status: status,
        message: 'Status izin ${_getPermissionName(type)}: ${status.name}',
      );
    } catch (e, stack) {
      AppLogger.e('Error checking permission: $type', error: e, stackTrace: stack);
      return PermissionResult(
        type: type,
        status: PermissionStatus.denied,
        message: 'Gagal memeriksa izin: $e',
      );
    }
  }

  @override
  Future<PermissionResult> requestPermission(AppPermissionType type) async {
    try {
      AppLogger.i('Requesting permission: ${_getPermissionName(type)}');

      if (type == AppPermissionType.gallery && !kIsWeb && Platform.isAndroid) {
        // Coba minta permission photos terlebih dahulu (Android 13+)
        var status = await Permission.photos.request();
        // Jika tidak di-grant (misal pada Android 12 atau di bawahnya yang tidak mendukung READ_MEDIA_IMAGES),
        // fallback ke permission storage
        if (!status.isGranted && !status.isLimited) {
          final storageStatus = await Permission.storage.request();
          if (storageStatus.isGranted) {
            status = storageStatus;
          } else if (storageStatus.isPermanentlyDenied) {
            status = storageStatus;
          }
        }

        AppLogger.i('Gallery permission result on Android: $status');
        String message;
        if (status.isGranted || status.isLimited) {
          message = 'Izin Galeri Foto & Media berhasil diberikan.';
        } else if (status.isPermanentlyDenied) {
          message =
              'Izin Galeri ditolak permanen. Silakan aktifkan via Pengaturan Perangkat.';
        } else {
          message = 'Izin Galeri ditolak pengguna.';
        }

        return PermissionResult(
          type: type,
          status: status,
          message: message,
        );
      }

      final permission = _mapTypeToPermission(type);
      final status = await permission.request();
      AppLogger.i('Permission result: ${_getPermissionName(type)} -> $status');

      String message;
      if (status.isGranted || status.isLimited) {
        message = 'Izin ${_getPermissionName(type)} berhasil diberikan.';
      } else if (status.isPermanentlyDenied) {
        message =
            'Izin ${_getPermissionName(type)} ditolak permanen. Silakan aktifkan via Pengaturan Perangkat.';
      } else {
        message = 'Izin ${_getPermissionName(type)} ditolak pengguna.';
      }

      return PermissionResult(
        type: type,
        status: status,
        message: message,
      );
    } catch (e, stack) {
      AppLogger.e('Error requesting permission: $type', error: e, stackTrace: stack);
      return PermissionResult(
        type: type,
        status: PermissionStatus.denied,
        message: 'Gagal meminta izin: $e',
      );
    }
  }

  @override
  Future<Map<AppPermissionType, PermissionResult>> requestMultiple(
    List<AppPermissionType> types,
  ) async {
    final Map<AppPermissionType, PermissionResult> results = {};
    for (final type in types) {
      final result = await requestPermission(type);
      results[type] = result;
    }
    return results;
  }

  @override
  Future<bool> openSettings() async {
    AppLogger.i('Opening application system settings for permissions...');
    return await openAppSettings();
  }
}
