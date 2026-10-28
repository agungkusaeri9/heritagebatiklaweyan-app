import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int perPage = 15,
    bool? isRead,
  });

  Future<int> markRead({
    List<int>? notificationIds,
    bool all = false,
  });

  Future<int> markAllRead();

  Future<bool> markSingleRead(int id);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int perPage = 15,
    bool? isRead,
  }) {
    return remoteDataSource.getNotifications(
      page: page,
      perPage: perPage,
      isRead: isRead,
    );
  }

  @override
  Future<int> markRead({
    List<int>? notificationIds,
    bool all = false,
  }) {
    return remoteDataSource.markRead(
      notificationIds: notificationIds,
      all: all,
    );
  }

  @override
  Future<int> markAllRead() {
    return remoteDataSource.markAllRead();
  }

  @override
  Future<bool> markSingleRead(int id) {
    return remoteDataSource.markSingleRead(id);
  }
}
