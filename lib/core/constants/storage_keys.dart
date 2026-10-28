/// Kunci penyimpanan (Storage Keys) untuk Secure Storage dan Shared Preferences
class StorageKeys {
  StorageKeys._();

  // === SECURE STORAGE KEYS (Data Sensitif/Terenkripsi) ===
  static const String accessToken = 'SECURE_ACCESS_TOKEN';
  static const String refreshToken = 'SECURE_REFRESH_TOKEN';
  static const String userPrivateKey = 'SECURE_USER_PRIVATE_KEY';

  // === LOCAL STORAGE KEYS (Data Non-Sensitif / SharedPreferences) ===
  static const String isDarkMode = 'PREF_IS_DARK_MODE';
  static const String lastLoggedInUsername = 'PREF_LAST_USERNAME';
  static const String hasCompletedOnboarding = 'PREF_HAS_COMPLETED_ONBOARDING';
  static const String appLanguage = 'PREF_APP_LANGUAGE';
  static const String cachedUserProfile = 'PREF_CACHED_USER_PROFILE';
  static const String cachedUserLocation = 'PREF_CACHED_USER_LOCATION';
  static const String searchHistory = 'PREF_SEARCH_HISTORY';
}
