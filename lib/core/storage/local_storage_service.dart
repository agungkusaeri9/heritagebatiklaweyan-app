import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../logging/app_logger.dart';

/// Service untuk data non-sensitif (Preferences, User settings, Cache flags)
abstract class ILocalStorageService {
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  Future<bool> setInt(String key, int value);
  int? getInt(String key);
  Future<bool> remove(String key);
  Future<bool> clear();

  // Helper convenience methods
  Future<void> saveLastUsername(String username);
  String? getLastUsername();
  Future<void> setDarkMode(bool isDark);
  bool isDarkMode();
}

class LocalStorageService implements ILocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  @override
  Future<bool> setString(String key, String value) {
    AppLogger.d('LocalStorage: setString $key');
    return _prefs.setString(key, value);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> setBool(String key, bool value) {
    AppLogger.d('LocalStorage: setBool $key = $value');
    return _prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  Future<bool> remove(String key) {
    AppLogger.d('LocalStorage: remove $key');
    return _prefs.remove(key);
  }

  @override
  Future<bool> clear() {
    AppLogger.w('LocalStorage: Clear all preferences');
    return _prefs.clear();
  }

  @override
  Future<void> saveLastUsername(String username) async {
    await setString(StorageKeys.lastLoggedInUsername, username);
  }

  @override
  String? getLastUsername() {
    return getString(StorageKeys.lastLoggedInUsername);
  }

  @override
  Future<void> setDarkMode(bool isDark) async {
    await setBool(StorageKeys.isDarkMode, isDark);
  }

  @override
  bool isDarkMode() {
    return getBool(StorageKeys.isDarkMode) ?? true; // Default dark theme for cyber theme
  }
}
