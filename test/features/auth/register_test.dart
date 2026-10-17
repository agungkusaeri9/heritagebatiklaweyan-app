import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/local_storage_service.dart';
import 'package:heritage_batik/core/storage/storage_providers.dart';
import 'package:heritage_batik/features/auth/presentation/views/register_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RegisterView (Create Account) Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
        ],
        child: const MaterialApp(
          home: RegisterView(),
        ),
      );
    }

    testWidgets('Renders curved header with title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(
        find.text('Fill your information below or register with your social account.'),
        findsOneWidget,
      );
      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('Renders 3 input fields with correct labels and placeholders',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Labels
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Placeholders / Hints
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('example@gmail.com'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);
    });

    testWidgets('Toggles password visibility when eye icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially password is obscured and shows visibility_outlined icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Now visibility_off_outlined icon should be shown
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Renders Terms & Conditions checkbox and link',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.textContaining('Agree with'), findsOneWidget);
      expect(find.textContaining('Term & Condition'), findsOneWidget);

      // Tap checkbox to toggle
      final checkboxFinder = find.byType(Checkbox);
      Checkbox checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isFalse);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      checkbox = tester.widget(checkboxFinder);
      expect(checkbox.value, isTrue);
    });

    testWidgets('Shows validation errors when form submitted empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Sign Up with empty fields
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please agree with the Term & Condition to continue'), findsOneWidget);
    });

    testWidgets('Footer contains Already have an account? Sign In',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Does not render social login buttons, dividers, or "Or sign up with"',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Or sign up with'), findsNothing);
      expect(find.text('Google'), findsNothing);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Facebook'), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });
  });
}
