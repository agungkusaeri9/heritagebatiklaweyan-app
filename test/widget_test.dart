import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/storage_providers.dart';
import 'package:heritage_batik/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const HeritageBatikApp(),
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    // Verify e-commerce login screen is rendered
    expect(find.text('Masuk ke Akun'), findsOneWidget);
  });
}
