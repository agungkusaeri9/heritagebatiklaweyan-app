import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_location_model.dart';

abstract class ILocationRemoteDataSource {
  Future<UserLocationModel?> getUserLocation();
  Future<UserLocationModel> updateUserLocation(UserLocationModel location);
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });
}

class LocationRemoteDataSource implements ILocationRemoteDataSource {
  final DioClient dioClient;

  LocationRemoteDataSource(this.dioClient);

  Dio get dio => dioClient.dio;

  Future<Response> _requestWithFallback({
    required String method,
    required List<String> endpoints,
    dynamic data,
  }) async {
    DioException? lastError;

    for (final endpoint in endpoints) {
      try {
        AppLogger.d('LocationRemoteDataSource: Trying $method $endpoint');
        final response = method.toUpperCase() == 'GET'
            ? await dio.get(endpoint)
            : await dio.put(endpoint, data: data);

        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return response;
        }
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode == 404) {
          AppLogger.w('Endpoint $endpoint returned 404, trying next candidate...');
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw const ApiException(message: 'Semua endpoint lokasi backend tidak merespon.');
  }

  @override
  Future<UserLocationModel?> getUserLocation() async {
    try {
      AppLogger.i('LocationRemoteDataSource: Mengambil lokasi pengguna dari server...');
      final candidateEndpoints = [
        ApiConstants.userLocation,
        '/user/location',
        '${ApiConstants.apiBaseUrl}/user/location',
      ];

      final response = await _requestWithFallback(
        method: 'GET',
        endpoints: candidateEndpoints,
      );

      final responseData = response.data;
      if (responseData is Map) {
        final innerData = responseData['data'];
        if (innerData == null) {
          return null; // Lokasi belum diatur di server
        }
        if (innerData is Map<String, dynamic>) {
          return UserLocationModel.fromJson(innerData);
        }
        if (innerData is Map) {
          return UserLocationModel.fromJson(Map<String, dynamic>.from(innerData));
        }
      }
      return null;
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        return null;
      }
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('LocationRemoteDataSource: Error getting user location', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil data lokasi dari server: $e');
    }
  }

  @override
  Future<UserLocationModel> updateUserLocation(UserLocationModel location) async {
    try {
      AppLogger.i('LocationRemoteDataSource: Menyimpan lokasi pengguna ke server: ${location.source}');
      final candidateEndpoints = [
        ApiConstants.userLocation,
        '/user/location',
        '${ApiConstants.apiBaseUrl}/user/location',
      ];

      final payload = location.toJson();
      final response = await _requestWithFallback(
        method: 'PUT',
        endpoints: candidateEndpoints,
        data: payload,
      );

      final responseData = response.data;
      if (responseData is Map) {
        final innerData = responseData['data'] ?? responseData;
        if (innerData is Map<String, dynamic>) {
          return UserLocationModel.fromJson(innerData);
        }
        if (innerData is Map) {
          return UserLocationModel.fromJson(Map<String, dynamic>.from(innerData));
        }
      }

      return location;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('LocationRemoteDataSource: Error updating user location', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal memperbarui lokasi di server: $e');
    }
  }

  @override
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      AppLogger.i(
        'LocationRemoteDataSource: Mengambil alamat lengkap dari koordinat ($latitude, $longitude) melalui Geoapify backend...',
      );
      final response = await dio.get(
        ApiConstants.getAddress(lat: latitude, lon: longitude),
      );
      final responseData = response.data;
      if (responseData is Map) {
        final data = responseData['data'];
        if (data is Map) {
          final formatted =
              data['formatted_address']?.toString() ??
              data['address_line1']?.toString();
          if (formatted != null && formatted.trim().isNotEmpty) {
            return formatted.trim();
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.w(
        'LocationRemoteDataSource: Gagal mengambil alamat dari Geoapify backend: $e',
      );
      return null;
    }
  }
}
