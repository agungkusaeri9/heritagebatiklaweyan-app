import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/storage_providers.dart';
import 'package:heritage_batik/features/store/data/datasources/store_remote_data_source.dart';
import 'package:heritage_batik/features/store/data/models/faq_model.dart';
import 'package:heritage_batik/features/store/data/models/payment_method_model.dart';
import 'package:heritage_batik/features/store/data/models/store_setting_model.dart';
import 'package:heritage_batik/features/store/presentation/viewmodels/store_providers.dart';
import 'package:heritage_batik/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStoreRemoteDataSource implements StoreRemoteDataSource {
  @override
  Future<StoreSettingModel> getStoreSetting() async {
    return const StoreSettingModel(name: 'Heritage Batik Test');
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    return [];
  }

  @override
  Future<List<FaqModel>> getFaqs() async {
    return [];
  }
}

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storeRemoteDataSourceProvider.overrideWithValue(MockStoreRemoteDataSource()),
        ],
        child: const HeritageBatikApp(),
      ),
    );

    // Initial pump menampilkan Splash Screen dengan logo
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    // Majukan waktu melewati delay splash screen (2 detik)
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    // Pengguna baru diarahkan ke Welcome Screen
    expect(find.text('ARBatika Makes You Feel Confident And Easy'), findsOneWidget);
    expect(find.text("Let's Get Started"), findsOneWidget);
  });

  testWidgets('App navigates from Welcome to login when Sign in is tapped',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storeRemoteDataSourceProvider
              .overrideWithValue(MockStoreRemoteDataSource()),
        ],
        child: const HeritageBatikApp(),
      ),
    );

    // Buka aplikasi melewati splash screen ke welcome screen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    // Pastikan berada di Welcome Screen
    expect(find.text('Sign in'), findsOneWidget);

    // Tap teks "Sign in"
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Verifikasi berpindah ke halaman login
    expect(find.text("Hi! Welcome back, you've been missed"), findsOneWidget);
  });
}
