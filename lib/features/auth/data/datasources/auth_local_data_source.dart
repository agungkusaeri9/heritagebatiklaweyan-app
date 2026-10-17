import 'dart:convert';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  });

  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAuthData();

  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();

  Future<void> saveLastUsername(String username);
  String? getLastUsername();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final ISecureStorageService secureStorage;
  final ILocalStorageService localStorage;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
    required this.localStorage,
  });

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await secureStorage.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await secureStorage.saveRefreshToken(refreshToken);
    }
    AppLogger.d('AuthLocalDataSource: Tokens saved securely');
  }

  @override
  Future<String?> getAccessToken() => secureStorage.getAccessToken();

  @override
  Future<String?> getRefreshToken() => secureStorage.getRefreshToken();

  @override
  Future<void> clearAuthData() async {
    await secureStorage.clearAuthTokens();
    await localStorage.remove(StorageKeys.cachedUserProfile);
    AppLogger.i('AuthLocalDataSource: Auth session cleared');
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await localStorage.setString(StorageKeys.cachedUserProfile, jsonString);
    AppLogger.d('AuthLocalDataSource: User cached locally');
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = localStorage.getString(StorageKeys.cachedUserProfile);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      } catch (e) {
        AppLogger.w('Failed to parse cached user: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveLastUsername(String username) {
    return localStorage.saveLastUsername(username);
  }

  @override
  String? getLastUsername() {
    return localStorage.getLastUsername();
  }
}
