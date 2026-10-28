import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:heritage_batik/features/notification/data/models/notification_model.dart';
import 'package:heritage_batik/features/notification/data/repositories/notification_repository.dart';
import 'package:heritage_batik/features/notification/presentation/viewmodels/notification_providers.dart';
import 'package:heritage_batik/features/notification/presentation/viewmodels/notification_state.dart';
import 'package:heritage_batik/features/notification/presentation/views/notification_view.dart';
import 'package:heritage_batik/features/notification/presentation/widgets/notification_skeleton.dart';

class MockNotificationRepository implements NotificationRepository {
  List<NotificationModel> mockNotifications = [];
  NotificationPaginationModel mockPagination = const NotificationPaginationModel(
    currentPage: 1,
    perPage: 10,
    total: 2,
    lastPage: 1,
    hasMorePages: false,
  );
  bool shouldThrow = false;
  List<int> markedReadIds = [];
  bool markedAllReadCalled = false;

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int perPage = 15,
    bool? isRead,
  }) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return NotificationListResult(
      notifications: mockNotifications,
      pagination: mockPagination,
    );
  }

  @override
  Future<int> markRead({List<int>? notificationIds, bool all = false}) async {
    if (notificationIds != null) {
      markedReadIds.addAll(notificationIds);
    }
    return notificationIds?.length ?? 0;
  }

  @override
  Future<int> markAllRead() async {
    markedAllReadCalled = true;
    return mockNotifications.length;
  }

  @override
  Future<bool> markSingleRead(int id) async {
    markedReadIds.add(id);
    return true;
  }
}

void main() {
  group('NotificationViewModel Tests', () {
    late MockNotificationRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockNotificationRepository();
      mockRepo.mockNotifications = [
        NotificationModel(
          id: 101,
          title: 'Promo Diskon 30%',
          message: 'Voucher spesial diskon batik cap.',
          recipientType: 'CUSTOMER',
          category: const NotificationCategoryModel(
            code: 'PROMO_DISCOUNT',
            name: 'Promo & Diskon',
          ),
          isRead: false,
          createdAt: DateTime.now(),
        ),
        NotificationModel(
          id: 102,
          title: 'Pesanan Dikirim',
          message: 'Resi kurir JNE sudah diterbitkan.',
          recipientType: 'CUSTOMER',
          category: const NotificationCategoryModel(
            code: 'ORDER_STATUS_UPDATE',
            name: 'Pembaruan Pesanan',
          ),
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial load updates state with notifications and unread count', () async {
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.loadNotifications();

      final state = container.read(notificationViewModelProvider);
      expect(state.status, NotificationStatus.success);
      expect(state.notifications.length, 2);
      expect(state.unreadCount, 2);
      expect(state.dateGroups.length, 2);
    });

    test('markSectionAsRead marks section items read and updates count', () async {
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.loadNotifications();

      var state = container.read(notificationViewModelProvider);
      expect(state.unreadCount, 2);

      final todaySection = state.dateGroups.first;
      await notifier.markSectionAsRead(todaySection);

      state = container.read(notificationViewModelProvider);
      expect(state.unreadCount, 1);
      expect(mockRepo.markedReadIds, contains(101));
      expect(state.notifications.first.isRead, isTrue);
    });

    test('markSingleAsRead marks specific item read', () async {
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.loadNotifications();
      await notifier.markSingleAsRead(102);

      final state = container.read(notificationViewModelProvider);
      expect(state.unreadCount, 1);
      expect(mockRepo.markedReadIds, contains(102));
      final item102 = state.notifications.firstWhere((i) => i.id == 102);
      expect(item102.isRead, isTrue);
    });

    test('markAllAsRead sets unread count to 0', () async {
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.loadNotifications();
      await notifier.markAllAsRead();

      final state = container.read(notificationViewModelProvider);
      expect(state.unreadCount, 0);
      expect(mockRepo.markedAllReadCalled, isTrue);
      expect(state.notifications.every((i) => i.isRead), isTrue);
    });

    test('loadNotifications handles error properly', () async {
      mockRepo.shouldThrow = true;
      final notifier = container.read(notificationViewModelProvider.notifier);
      await notifier.loadNotifications();

      final state = container.read(notificationViewModelProvider);
      expect(state.status, NotificationStatus.error);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('NotificationView Widget Tests', () {
    testWidgets('Renders app bar, unread badge, date sections, and notification items', (tester) async {
      final mockRepo = MockNotificationRepository();
      final now = DateTime.now();

      mockRepo.mockNotifications = [
        NotificationModel(
          id: 1,
          title: 'Flash Sale Batik Laweyan 25%',
          message: 'Gunakan kupon batik sekarang juga.',
          recipientType: 'CUSTOMER',
          category: const NotificationCategoryModel(
            code: 'PROMO_DISCOUNT',
            name: 'Promo',
          ),
          isRead: false,
          createdAt: now,
        ),
        NotificationModel(
          id: 2,
          title: 'Pesanan Selesai',
          message: 'Paket sarung batik telah diterima.',
          recipientType: 'CUSTOMER',
          category: const NotificationCategoryModel(
            code: 'ORDER_STATUS_UPDATE',
            name: 'Pesanan',
          ),
          isRead: false,
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NotificationView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. App Bar Title
      expect(find.text('Notification'), findsOneWidget);

      // 2. Unread Badge "2 NEW"
      expect(find.text('2 NEW'), findsOneWidget);

      // 3. Date Section Header & Action
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Mark all as read'), findsOneWidget);

      // 4. Notification Items Content
      expect(find.text('Flash Sale Batik Laweyan 25%'), findsOneWidget);
      expect(find.text('Gunakan kupon batik sekarang juga.'), findsOneWidget);
      expect(find.text('Pesanan Selesai'), findsOneWidget);
    });

    testWidgets('Renders Empty State when no notifications exist', (tester) async {
      final mockRepo = MockNotificationRepository();
      mockRepo.mockNotifications = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NotificationView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No Notifications Yet'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('Renders Error State when API fails', (tester) async {
      final mockRepo = MockNotificationRepository();
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NotificationView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to Load Notifications'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Renders NotificationSkeleton while loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSkeleton(),
          ),
        ),
      );

      expect(find.byType(NotificationSkeleton), findsOneWidget);
    });
  });
}
