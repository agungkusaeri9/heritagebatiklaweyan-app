import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/local_storage_service.dart';
import 'package:heritage_batik/core/storage/storage_providers.dart';
import 'package:heritage_batik/features/onboarding/data/models/onboarding_item.dart';
import 'package:heritage_batik/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:heritage_batik/features/onboarding/presentation/views/welcome_view.dart';
import 'package:heritage_batik/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:heritage_batik/features/onboarding/presentation/widgets/phone_mockup_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Onboarding & Welcome Tests', () {
    test('OnboardingItem model configuration has 3 items', () {
      expect(OnboardingItem.items.length, 3);
      expect(OnboardingItem.items[0].title, 'Seamless Shopping Experience');
      expect(OnboardingItem.items[1].title, 'Wishlist: Where Fashion Dreams Begin');
      expect(OnboardingItem.items[2].title, 'Swift and Reliable Delivery');
    });

    testWidgets('OnboardingPageIndicator renders correct dot count and active state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingPageIndicator(
              count: 3,
              currentIndex: 1,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children.length, 3);
    });

    testWidgets('WelcomeView renders headline, hero, and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeView(),
        ),
      );

      expect(find.text('ARBatika Makes You Feel Confident And Easy'), findsOneWidget);
      expect(find.text("Let's Get Started"), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('OnboardingView renders first slide with shopping mockup and skip button',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
          ],
          child: const MaterialApp(
            home: OnboardingView(),
          ),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Seamless Shopping Experience'), findsOneWidget);
      expect(find.byType(PhoneMockupWidget), findsOneWidget);
      expect(find.byType(OnboardingPageIndicator), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });
  });
}
