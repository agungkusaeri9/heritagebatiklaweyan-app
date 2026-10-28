import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/notification/data/models/notification_model.dart';
import 'package:heritage_batik/features/notification/presentation/viewmodels/notification_state.dart';

void main() {
  group('NotificationModel & Serialization Tests', () {
    test('NotificationModel parses JSON correctly', () {
      final json = {
        'id': 10,
        'user_id': 1,
        'title': 'Flash Sale Batik Pekalongan Diskon 25%',
        'message': 'Gunakan kode voucher BATIK25 saat checkout.',
        'recipient_type': 'CUSTOMER',
        'category': {
          'code': 'PROMO_DISCOUNT',
          'name': 'Promo & Diskon Spesial',
        },
        'is_read': false,
        'read_at': null,
        'created_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 10);
      expect(model.userId, 1);
      expect(model.title, 'Flash Sale Batik Pekalongan Diskon 25%');
      expect(model.message, 'Gunakan kode voucher BATIK25 saat checkout.');
      expect(model.recipientType, 'CUSTOMER');
      expect(model.category?.code, 'PROMO_DISCOUNT');
      expect(model.category?.name, 'Promo & Diskon Spesial');
      expect(model.categoryCode, 'PROMO_DISCOUNT');
      expect(model.categoryName, 'Promo & Diskon Spesial');
      expect(model.isRead, isFalse);
      expect(model.readAt, isNull);
      expect(model.timeAgo, '15m ago');
    });

    test('NotificationModel copyWith updates fields properly', () {
      final model = NotificationModel(
        id: 1,
        title: 'Pengumuman Toko',
        message: 'Toko tutup hari Minggu.',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final updated = model.copyWith(isRead: true, readAt: DateTime.now());
      expect(updated.id, 1);
      expect(updated.title, 'Pengumuman Toko');
      expect(updated.isRead, isTrue);
      expect(updated.readAt, isNotNull);
    });

    test('NotificationPaginationModel parses pagination metadata', () {
      final json = {
        'current_page': 1,
        'per_page': 10,
        'total': 25,
        'last_page': 3,
        'has_more_pages': true,
      };

      final pagination = NotificationPaginationModel.fromJson(json);
      expect(pagination.currentPage, 1);
      expect(pagination.perPage, 10);
      expect(pagination.total, 25);
      expect(pagination.lastPage, 3);
      expect(pagination.hasMorePages, isTrue);
    });
  });

  group('Notification Date Grouping Tests', () {
    test('Groups notifications into Today, Yesterday, and Older Dates', () {
      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day, 10, 30);
      final yesterdayTime = todayTime.subtract(const Duration(days: 1));
      final olderTime = todayTime.subtract(const Duration(days: 4));

      final items = [
        NotificationModel(
          id: 1,
          title: 'Notif Hari Ini 1',
          message: 'Pesan hari ini',
          createdAt: todayTime,
          isRead: false,
        ),
        NotificationModel(
          id: 2,
          title: 'Notif Hari Ini 2',
          message: 'Pesan hari ini ke-2',
          createdAt: todayTime.subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        NotificationModel(
          id: 3,
          title: 'Notif Kemarin',
          message: 'Pesan kemarin',
          createdAt: yesterdayTime,
          isRead: false,
        ),
        NotificationModel(
          id: 4,
          title: 'Notif Lebih Lama',
          message: 'Pesan lama',
          createdAt: olderTime,
          isRead: true,
        ),
      ];

      final state = NotificationState(notifications: items);
      final groups = state.dateGroups;

      expect(groups.length, 3);

      // Kelompok 1: Today
      expect(groups[0].title, 'Today');
      expect(groups[0].items.length, 2);
      expect(groups[0].unreadCount, 1);
      expect(groups[0].unreadNotificationIds, [1]);
      expect(groups[0].allNotificationIds, [1, 2]);

      // Kelompok 2: Yesterday
      expect(groups[1].title, 'Yesterday');
      expect(groups[1].items.length, 1);
      expect(groups[1].unreadCount, 1);
      expect(groups[1].unreadNotificationIds, [3]);

      // Kelompok 3: Older Date
      expect(groups[2].items.length, 1);
      expect(groups[2].unreadCount, 0);
      expect(groups[2].unreadNotificationIds, isEmpty);
    });
  });
}
