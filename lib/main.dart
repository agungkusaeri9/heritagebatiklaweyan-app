import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/api_constants.dart';
import 'core/logging/app_logger.dart';
import 'core/network/session_expiry_bus.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/viewmodels/auth_providers.dart';
import 'features/wishlist/presentation/viewmodels/wishlist_providers.dart';
import 'features/notification/presentation/viewmodels/notification_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/widgets/app_snackbar.dart';
import 'features/home/presentation/widgets/floating_tryon_progress.dart';
import 'features/home/presentation/viewmodels/tryon_progress_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    AppLogger.i('BOOT: Firebase berhasil diinisialisasi.');
  } catch (e, stack) {
    AppLogger.e('BOOT: Gagal inisialisasi Firebase: $e', error: e, stackTrace: stack);
  }

  // Inisialisasi Environment Variables (.env)
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.i(
      'BOOT: Environment (.env) berhasil dimuat. Base URL: ${ApiConstants.baseUrl}',
    );
  } catch (e) {
    AppLogger.w(
      'BOOT: File .env tidak ditemukan atau gagal dimuat, menggunakan default fallback (${ApiConstants.baseUrl}): $e',
    );
  }

  // Inisialisasi SharedPreferences untuk penyimpanan non-sensitif
  late final SharedPreferences sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
    AppLogger.i('BOOT: SharedPreferences berhasil diinisialisasi.');
  } catch (e, stack) {
    AppLogger.e(
      'BOOT: Gagal inisialisasi SharedPreferences, menggunakan fallback in-memory: $e',
      error: e,
      stackTrace: stack,
    );
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const HeritageBatikApp(),
    ),
  );
}

class HeritageBatikApp extends ConsumerStatefulWidget {
  const HeritageBatikApp({super.key});

  @override
  ConsumerState<HeritageBatikApp> createState() => _HeritageBatikAppState();
}

class _HeritageBatikAppState extends ConsumerState<HeritageBatikApp> {
  StreamSubscription<void>? _sessionExpirySub;

  @override
  void initState() {
    super.initState();
    // Ketika token tak bisa di-refresh (401), paksa logout agar AuthState
    // menjadi unauthenticated dan router guard mengarahkan ke /login.
    _sessionExpirySub = SessionExpiryBus.stream.listen((_) {
      AppLogger.w('App: Sesi berakhir. Mengarahkan ke halaman login...');
      ref.read(authViewModelProvider.notifier).logout();
    });

    // Inisialisasi listener FCM Foreground & Background Click
    _initFcmListeners();

    // Muat data notifikasi & unread badge saat aplikasi pertama kali aktif
    Future.microtask(() {
      if (ref.read(authViewModelProvider).isAuthenticated) {
        ref.read(notificationViewModelProvider.notifier).loadNotifications();
      }
    });
  }

  void _initFcmListeners() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {},
      );

      // Buat notification channel di Android 8+
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i('FCM Foreground Message received: ${message.notification?.title}');
        
        if (ref.read(authViewModelProvider).isAuthenticated) {
          ref.read(notificationViewModelProvider.notifier).loadNotifications();
        }

        RemoteNotification? notification = message.notification;

        // Tampilkan notifikasi sistem di atas (notification tray / heads-up) alih-alih toast
        if (notification != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title ?? '',
            notification.body ?? '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                channelDescription: 'This channel is used for important notifications.',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.i('FCM Message clicked: ${message.data}');
        if (ref.read(authViewModelProvider).isAuthenticated) {
          ref.read(notificationViewModelProvider.notifier).loadNotifications();
        }
      });
    } catch (e) {
      AppLogger.w('Gagal menginisialisasi FCM listeners: $e');
    }
  }

  @override
  void dispose() {
    _sessionExpirySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Segarkan wishlist dan notifikasi saat status login berubah (login -> muat, logout -> kosong).
    ref.listen<bool>(
      authViewModelProvider.select((s) => s.isAuthenticated),
      (previous, next) {
        if (previous == next) return;
        final wishlist = ref.read(wishlistViewModelProvider.notifier);
        final notifications = ref.read(notificationViewModelProvider.notifier);
        if (next) {
          wishlist.loadWishlist();
          notifications.loadNotifications();
        } else {
          ref.invalidate(wishlistViewModelProvider);
          ref.invalidate(notificationViewModelProvider);
        }
      },
    );

    return MaterialApp.router(
      title: 'ARBatik',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return _AppShellWithOverlay(child: child);
      },
    );
  }
}

class _AppShellWithOverlay extends ConsumerWidget {
  final Widget? child;
  const _AppShellWithOverlay({this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActive = ref.watch(
      tryOnProgressProvider.select((s) => s.hasActiveTasks),
    );

    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        if (hasActive)
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 90,
            child: const FloatingTryOnProgress(),
          ),
      ],
    );
  }
}
