import '../../domain/entities/auth_token_entity.dart';
import 'user_model.dart';

/// DTO Response Autentikasi dari API backend
class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;

    final token = json['access_token']?.toString() ??
        json['token']?.toString() ??
        json['plainTextToken']?.toString() ??
        data?['access_token']?.toString() ??
        data?['token']?.toString() ??
        data?['plainTextToken']?.toString() ??
        '';

    final userRaw = json['user'] ?? data?['user'] ?? (data ?? json);
    final userMap = userRaw is Map<String, dynamic> ? userRaw : json;

    return AuthResponseModel(
      accessToken: token,
      refreshToken: json['refresh_token']?.toString() ?? data?['refresh_token']?.toString(),
      tokenType: json['token_type']?.toString() ?? data?['token_type']?.toString() ?? 'Bearer',
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : (data?['expires_in'] is int ? data!['expires_in'] as int : 3600),
      user: UserModel.fromJson(userMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }

  AuthTokenEntity toTokenEntity() {
    return AuthTokenEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
    );
  }
}
