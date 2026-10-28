import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_providers.dart';
import 'notification_state.dart';

class NotificationViewModel extends Notifier<NotificationState> {
  late final NotificationRepository _repository;

  @override
  NotificationState build() {
    _repository = ref.watch(notificationRepositoryProvider);
    return const NotificationState();
  }

  /// Memuat notifikasi pertama kali atau memuat ulang (pull-to-refresh)
  Future<void> loadNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(
        status: NotificationStatus.loading,
        errorMessage: null,
      );
    }

    try {
      final result = await _repository.getNotifications(page: 1, perPage: 15);

      final unreadCount = result.notifications.where((item) => !item.isRead).length;

      state = state.copyWith(
        status: NotificationStatus.success,
        isRefreshing: false,
        errorMessage: null,
        notifications: result.notifications,
        pagination: result.pagination,
        unreadCount: unreadCount,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memuat notifikasi', error: e, stackTrace: stack);
      state = state.copyWith(
        status: NotificationStatus.error,
        isRefreshing: false,
        errorMessage: 'Gagal memuat notifikasi. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Memuat halaman berikutnya ketika scrolling mencapai batas bawah (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMorePages || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.pagination.currentPage + 1;
      final result = await _repository.getNotifications(
        page: nextPage,
        perPage: state.pagination.perPage,
      );

      final updatedList = [...state.notifications, ...result.notifications];
      final unreadCount = updatedList.where((item) => !item.isRead).length;

      state = state.copyWith(
        isLoadingMore: false,
        notifications: updatedList,
        pagination: result.pagination,
        unreadCount: unreadCount,
      );
    } catch (e, stack) {
      AppLogger.e('Gagal memuat halaman notifikasi berikutnya', error: e, stackTrace: stack);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Menandai semua notifikasi dalam sebuah kelompok tanggal sebagai terbaca
  Future<void> markSectionAsRead(NotificationDateGroup section) async {
    final unreadIds = section.unreadNotificationIds;
    if (unreadIds.isEmpty) return;

    // Optimistic update
    final updatedList = state.notifications.map((item) {
      if (unreadIds.contains(item.id)) {
        return item.copyWith(isRead: true, readAt: DateTime.now());
      }
      return item;
    }).toList();

    final newUnreadCount = updatedList.where((item) => !item.isRead).length;

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnreadCount,
    );

    try {
      await _repository.markRead(notificationIds: unreadIds);
    } catch (e, stack) {
      AppLogger.e('Gagal menandai kelompok notifikasi sebagai dibaca', error: e, stackTrace: stack);
    }
  }

  /// Menandai semua notifikasi yang ada sebagai terbaca
  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;

    // Optimistic update
    final updatedList = state.notifications.map((item) {
      return item.isRead ? item : item.copyWith(isRead: true, readAt: DateTime.now());
    }).toList();

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    );

    try {
      await _repository.markAllRead();
    } catch (e, stack) {
      AppLogger.e('Gagal menandai semua notifikasi sebagai dibaca', error: e, stackTrace: stack);
    }
  }

  /// Menandai sebuah notifikasi tunggal sebagai terbaca
  Future<void> markSingleAsRead(int notificationId) async {
    final index = state.notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;

    final currentItem = state.notifications[index];
    if (currentItem.isRead) return;

    // Optimistic update
    final updatedList = List<NotificationModel>.from(state.notifications);
    updatedList[index] = currentItem.copyWith(isRead: true, readAt: DateTime.now());

    final newUnreadCount = updatedList.where((item) => !item.isRead).length;

    state = state.copyWith(
      notifications: updatedList,
      unreadCount: newUnreadCount,
    );

    try {
      await _repository.markSingleRead(notificationId);
    } catch (e, stack) {
      AppLogger.e('Gagal menandai notifikasi $notificationId sebagai dibaca', error: e, stackTrace: stack);
    }
  }
}
