import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/features/profile/presentation/widgets/logout_confirmation_bottom_sheet.dart';

void main() {
  Widget buildTestWidget({Future<void> Function()? onLogout}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                LogoutConfirmationBottomSheet.show(context, onLogout: onLogout);
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );
  }

  group('LogoutConfirmationBottomSheet Widget Tests', () {
    testWidgets('Displays title, confirmation message, Cancel and Yes, Logout buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Open bottom sheet
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Yes, Logout'), findsOneWidget);
    });

    testWidgets('Tapping Cancel closes the bottom sheet without executing logout', (tester) async {
      bool logoutCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          onLogout: () async {
            logoutCalled = true;
          },
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify sheet is closed and logout was not called
      expect(find.text('Are you sure you want to log out?'), findsNothing);
      expect(logoutCalled, isFalse);
    });
  });
}
