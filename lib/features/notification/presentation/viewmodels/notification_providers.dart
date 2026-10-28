import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_state.dart';
import 'notification_viewmodel.dart';

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRemoteDataSourceImpl(
    dio: dio,
    dioClient: dioClient,
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});

final notificationViewModelProvider =
    NotifierProvider<NotificationViewModel, NotificationState>(() {
  return NotificationViewModel();
});

/// Provider sederhana untuk memantau jumlah notifikasi yang belum dibaca (misal untuk HomeHeader)
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationViewModelProvider);
  return state.unreadCount;
});
