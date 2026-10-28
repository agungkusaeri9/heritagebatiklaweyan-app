import '../../data/models/notification_model.dart';

enum NotificationStatus { initial, loading, success, error }

class NotificationState {
  final NotificationStatus status;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<NotificationModel> notifications;
  final NotificationPaginationModel pagination;
  final int unreadCount;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.notifications = const [],
    this.pagination = const NotificationPaginationModel.empty(),
    this.unreadCount = 0,
  });

  bool get isLoading => status == NotificationStatus.loading;
  bool get isSuccess => status == NotificationStatus.success;
  bool get isError => status == NotificationStatus.error;
  bool get isEmpty => !isLoading && notifications.isEmpty;
  bool get hasMorePages => pagination.hasMorePages;

  NotificationState copyWith({
    NotificationStatus? status,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    List<NotificationModel>? notifications,
    NotificationPaginationModel? pagination,
    int? unreadCount,
  }) {
    return NotificationState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      notifications: notifications ?? this.notifications,
      pagination: pagination ?? this.pagination,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Mengelompokkan notifikasi berdasarkan tanggal (Today, Yesterday, Date)
  List<NotificationDateGroup> get dateGroups {
    if (notifications.isEmpty) return const [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Map tanggal (yyyy-MM-dd) -> List<NotificationModel>
    final Map<DateTime, List<NotificationModel>> groupedMap = {};

    for (final item in notifications) {
      final dateKey = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(item);
    }

    // Urutkan tanggal dari yang paling baru ke lama
    final sortedKeys = groupedMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((date) {
      String groupTitle;
      if (date == today) {
        groupTitle = 'Today';
      } else if (date == yesterday) {
        groupTitle = 'Yesterday';
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final month = _monthName(date.month);
        final year = date.year;
        groupTitle = '$day $month $year';
      }

      return NotificationDateGroup(
        title: groupTitle,
        date: date,
        items: groupedMap[date]!,
      );
    }).toList();
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
