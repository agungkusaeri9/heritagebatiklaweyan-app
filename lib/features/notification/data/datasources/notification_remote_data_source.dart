import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

/// Hasil query daftar notifikasi beserta info paginasi
class NotificationListResult {
  final List<NotificationModel> notifications;
  final NotificationPaginationModel pagination;

  const NotificationListResult({
    required this.notifications,
    required this.pagination,
  });
}

abstract class NotificationRemoteDataSource {
  /// Mengambil daftar notifikasi pengguna dengan pagination
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int perPage = 15,
    bool? isRead,
  });

  /// Menandai kumpulan ID notifikasi tertentu atau semua sebagai sudah dibaca
  Future<int> markRead({
    List<int>? notificationIds,
    bool all = false,
  });

  /// Menandai seluruh notifikasi pengguna sebagai sudah dibaca
  Future<int> markAllRead();

  /// Menandai sebuah notifikasi tunggal sebagai sudah dibaca
  Future<bool> markSingleRead(int id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;
  final DioClient dioClient;

  NotificationRemoteDataSourceImpl({
    required this.dio,
    required this.dioClient,
  });

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int perPage = 15,
    bool? isRead,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (isRead != null) {
        queryParams['is_read'] = isRead;
      }

      AppLogger.d('Mengambil data notifikasi dari ${ApiConstants.notifications} (page: $page, perPage: $perPage)');

      final response = await dio.get(
        ApiConstants.notifications,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final rawData = responseData['data'];
        final List<NotificationModel> list = [];
        if (rawData is List) {
          for (final item in rawData) {
            if (item is Map<String, dynamic>) {
              list.add(NotificationModel.fromJson(item));
            }
          }
        }

        NotificationPaginationModel pagination = const NotificationPaginationModel.empty();
        final meta = responseData['meta'];
        if (meta is Map<String, dynamic> && meta['pagination'] is Map<String, dynamic>) {
          pagination = NotificationPaginationModel.fromJson(meta['pagination'] as Map<String, dynamic>);
        }

        return NotificationListResult(
          notifications: list,
          pagination: pagination,
        );
      }

      return const NotificationListResult(
        notifications: [],
        pagination: NotificationPaginationModel.empty(),
      );
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal mengambil daftar notifikasi', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal mengambil daftar notifikasi: $e');
    }
  }

  @override
  Future<int> markRead({
    List<int>? notificationIds,
    bool all = false,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (all) {
        payload['all'] = true;
      } else if (notificationIds != null && notificationIds.isNotEmpty) {
        payload['notification_ids'] = notificationIds;
      } else {
        payload['all'] = true;
      }

      AppLogger.d('Menandai notifikasi sebagai terbaca via ${ApiConstants.notificationsMarkRead}: $payload');

      final response = await dio.post(
        ApiConstants.notificationsMarkRead,
        data: payload,
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData['data'] is Map<String, dynamic>) {
        final data = responseData['data'] as Map<String, dynamic>;
        return (data['updated_count'] as num?)?.toInt() ?? 0;
      }

      return 0;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menandai notifikasi sebagai dibaca', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menandai notifikasi dibaca: $e');
    }
  }

  @override
  Future<int> markAllRead() async {
    try {
      AppLogger.d('Menandai semua notifikasi terbaca via ${ApiConstants.notificationsMarkAllRead}');

      final response = await dio.post(ApiConstants.notificationsMarkAllRead);

      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData['data'] is Map<String, dynamic>) {
        final data = responseData['data'] as Map<String, dynamic>;
        return (data['updated_count'] as num?)?.toInt() ?? 0;
      }

      return 0;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menandai semua notifikasi sebagai dibaca', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menandai semua notifikasi: $e');
    }
  }

  @override
  Future<bool> markSingleRead(int id) async {
    try {
      final endpoint = ApiConstants.notificationMarkSingleRead(id);
      AppLogger.d('Menandai notifikasi id $id terbaca via $endpoint');

      final response = await dio.post(endpoint);

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final meta = responseData['meta'];
        if (meta is Map<String, dynamic> && meta['status'] == 'success') {
          return true;
        }
      }

      return true;
    } on DioException catch (dioErr) {
      throw dioClient.handleDioError(dioErr);
    } catch (e, stack) {
      AppLogger.e('Gagal menandai notifikasi tunggal dibaca', error: e, stackTrace: stack);
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal menandai notifikasi dibaca: $e');
    }
  }
}
