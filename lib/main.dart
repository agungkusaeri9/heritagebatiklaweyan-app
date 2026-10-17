import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi logging
  AppLogger.i('BOOT: Memulai aplikasi Heritage Batik Laweyan...');

  // Inisialisasi SharedPreferences untuk penyimpanan non-sensitif
  final sharedPreferences = await SharedPreferences.getInstance();
  AppLogger.i('BOOT: SharedPreferences berhasil diinisialisasi.');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const HeritageBatikApp(),
    ),
  );
}

class HeritageBatikApp extends ConsumerWidget {
  const HeritageBatikApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Heritage Batik Laweyan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
