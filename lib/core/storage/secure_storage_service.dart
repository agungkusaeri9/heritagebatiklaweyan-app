import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';
import '../errors/exceptions.dart';
import '../logging/app_logger.dart';

/// Service untuk menyimpan data sensitif (seperti JWT Access Token & Refresh Token)
/// menggunakan Hardware-backed Keystore / Keychain terenkripsi.
abstract class ISecureStorageService {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> clearAuthTokens();
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clearAll();
}

class SecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<void> saveAccessToken(String token) async {
    await write(StorageKeys.accessToken, token);
    AppLogger.d('SecureStorage: Access token encrypted & saved.');
  }

  @override
  Future<String?> getAccessToken() async {
    return await read(StorageKeys.accessToken);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await write(StorageKeys.refreshToken, token);
    AppLogger.d('SecureStorage: Refresh token encrypted & saved.');
  }

  @override
  Future<String?> getRefreshToken() async {
    return await read(StorageKeys.refreshToken);
  }

  @override
  Future<void> clearAuthTokens() async {
    try {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
      AppLogger.i('SecureStorage: Auth tokens cleared.');
    } catch (e, stack) {
      AppLogger.e('SecureStorage: Failed to clear auth tokens', error: e, stackTrace: stack);
      throw StorageException('Gagal menghapus token autentikasi: $e');
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, stack) {
      AppLogger.e('SecureStorage write error for key: $key', error: e, stackTrace: stack);
      throw StorageException('Gagal menulis data sensitif: $e');
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, stack) {
      AppLogger.e('SecureStorage read error for key: $key', error: e, stackTrace: stack);
      throw StorageException('Gagal membaca data sensitif: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, stack) {
      AppLogger.e('SecureStorage delete error for key: $key', error: e, stackTrace: stack);
      throw StorageException('Gagal menghapus data: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.w('SecureStorage: All encrypted credentials wiped.');
    } catch (e, stack) {
      AppLogger.e('SecureStorage clearAll error', error: e, stackTrace: stack);
      throw StorageException('Gagal membersihkan secure storage: $e');
    }
  }
}
