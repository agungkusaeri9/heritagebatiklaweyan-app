import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/local_storage_service.dart';
import 'package:heritage_batik/core/storage/storage_providers.dart';
import 'package:heritage_batik/features/auth/domain/entities/user_entity.dart';
import 'package:heritage_batik/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:heritage_batik/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:heritage_batik/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:heritage_batik/features/profile/data/models/profile_menu_item_model.dart';
import 'package:heritage_batik/features/profile/presentation/views/profile_view.dart';
import 'package:heritage_batik/features/profile/presentation/views/your_profile_view.dart';
import 'package:heritage_batik/features/profile/presentation/widgets/profile_menu_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthViewModel extends AuthViewModel {
  final AuthState initialTestState;
  bool updateProfileCalled = false;
  String? lastUpdatedName;
  String? lastUpdatedPhone;
  String? lastUpdatedGender;

  FakeAuthViewModel(this.initialTestState);

  @override
  AuthState build() => initialTestState;

  @override
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String gender,
    String? avatar,
    String? avatarFilePath,
  }) async {
    updateProfileCalled = true;
    lastUpdatedName = name;
    lastUpdatedPhone = phone;
    lastUpdatedGender = gender;

    final updatedUser = state.user?.copyWith(
      name: name,
      phone: phone,
      gender: gender,
      avatarUrl: avatar,
    );

    state = state.copyWith(
      user: updatedUser,
      status: AuthStatus.authenticated,
    );
    return true;
  }
}

void main() {
  final sampleUser = UserEntity(
    id: '1',
    name: 'Agung Kusaeri',
    email: 'agung@example.com',
    username: 'agungkusaeri',
    phone: '+6281234567890',
    gender: 'male',
    role: 'customer',
    avatarUrl: 'https://example.com/avatar.jpg',
    createdAt: DateTime(2026, 1, 1),
  );

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('YourProfileView UI & Functional Tests', () {
    testWidgets('Renders Your Profile header, pre-filled user inputs, avatar, and Verified email badge', (tester) async {
      final fakeAuth = FakeAuthViewModel(
        AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
            authViewModelProvider.overrideWith(() => fakeAuth),
          ],
          child: const MaterialApp(
            home: YourProfileView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header elements
      expect(find.text('Your Profile'), findsOneWidget);
      expect(find.byKey(const Key('your_profile_back_button')), findsOneWidget);
      expect(find.text('Kelola dan perbarui informasi akun Heritage Batik Anda'), findsOneWidget);

      // 2. Avatar & Camera button
      expect(find.byKey(const Key('your_profile_avatar_tap')), findsOneWidget);
      expect(find.byKey(const Key('your_profile_camera_button')), findsOneWidget);

      // 3. Pre-filled Full Name input
      final nameFinder = find.byKey(const Key('your_profile_name_input'));
      expect(nameFinder, findsOneWidget);
      expect(find.text('Agung Kusaeri'), findsOneWidget);

      // 4. Pre-filled Email Address input (read-only with Verified badge)
      final emailFinder = find.byKey(const Key('your_profile_email_input'));
      expect(emailFinder, findsOneWidget);
      expect(find.text('agung@example.com'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);

      // 5. Pre-filled Phone Number (+62 chip & digits)
      expect(find.text('+62'), findsOneWidget);
      expect(find.text('81234567890'), findsOneWidget);

      // 6. Pre-filled Gender dropdown
      expect(find.text('Laki-laki (Male)'), findsOneWidget);

      // 7. Save Changes button
      expect(find.byKey(const Key('your_profile_save_button')), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Shows bottom sheet when camera button on avatar is tapped', (tester) async {
      final fakeAuth = FakeAuthViewModel(
        AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
            authViewModelProvider.overrideWith(() => fakeAuth),
          ],
          child: const MaterialApp(
            home: YourProfileView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap camera button
      await tester.tap(find.byKey(const Key('your_profile_camera_button')));
      await tester.pumpAndSettle();

      // Verify bottom sheet options
      expect(find.text('Foto Profil Pengguna'), findsOneWidget);
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
      expect(find.text('Gunakan Avatar Bawaan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('Validates Full Name and Phone Number when submitted empty', (tester) async {
      final fakeAuth = FakeAuthViewModel(
        AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
            authViewModelProvider.overrideWith(() => fakeAuth),
          ],
          child: const MaterialApp(
            home: YourProfileView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear Name input
      final nameFinder = find.byKey(const Key('your_profile_name_input'));
      await tester.enterText(nameFinder, '');

      // Tap Save Changes
      await tester.tap(find.byKey(const Key('your_profile_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(fakeAuth.updateProfileCalled, isFalse);
    });

    testWidgets('Calls updateProfile and updates state when form is valid', (tester) async {
      final fakeAuth = FakeAuthViewModel(
        AuthState(
          status: AuthStatus.authenticated,
          user: sampleUser,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(LocalStorageService(prefs)),
            authViewModelProvider.overrideWith(() => fakeAuth),
          ],
          child: const MaterialApp(
            home: YourProfileView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change name to "Agung Kusaeri Baru"
      final nameFinder = find.byKey(const Key('your_profile_name_input'));
      await tester.enterText(nameFinder, 'Agung Kusaeri Baru');

      // Tap Save Changes
      await tester.tap(find.byKey(const Key('your_profile_save_button')));
      await tester.pumpAndSettle();

      expect(fakeAuth.updateProfileCalled, isTrue);
      expect(fakeAuth.lastUpdatedName, 'Agung Kusaeri Baru');
      expect(fakeAuth.lastUpdatedPhone, '+6281234567890');
    });

    testWidgets('ProfileMenuList contains Your profile menu with correct route', (tester) async {
      ProfileMenuItemModel? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuList(
              onMenuItemTap: (item) {
                tappedItem = item;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your profile'), findsOneWidget);

      await tester.tap(find.text('Your profile'));
      await tester.pumpAndSettle();

      expect(tappedItem?.id, 'your_profile');
      expect(tappedItem?.route, '/your-profile');
    });
  });
}

