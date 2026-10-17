import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';
import 'secure_storage_service.dart';

/// Provider instance SharedPreferences (di-override saat main.dart startup)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main.dart');
});

/// Provider Secure Storage Service untuk data sensitif (Token, Kunci Enkripsi)
final secureStorageServiceProvider = Provider<ISecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider Local Storage Service untuk data non-sensitif (Preferences, Settings)
final localStorageServiceProvider = Provider<ILocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});
