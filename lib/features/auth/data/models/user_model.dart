import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/user_entity.dart';

/// DTO Model Pengguna dengan serialization JSON dan mapping ke Entity
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.username,
    super.phone,
    super.gender,
    required super.role,
    super.avatarUrl,
    super.isProfileCompleteExplicit,
    super.isEmailVerified = false,
    required super.createdAt,
  });

  /// Normalisasi URL avatar dari backend (mengubah localhost/127.0.0.1 atau path relatif ke host server)
  static String? normalizeAvatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    var trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://127.0.0.1:8000') ||
        trimmed.startsWith('http://localhost:8000')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        return '${ApiConstants.serverUrl}${uri.path}';
      }
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${ApiConstants.serverUrl}$trimmed';
    }
    return '${ApiConstants.serverUrl}/$trimmed';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['avatar_url']?.toString() ??
        json['profile_photo_url']?.toString() ??
        json['avatar']?.toString();

    return UserModel(
      id: json['id'] != null
          ? json['id'].toString()
          : (json['_id']?.toString() ??
              'usr_${DateTime.now().millisecondsSinceEpoch}'),
      name: json['name']?.toString() ??
          json['username']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ??
          json['name']?.toString() ??
          '',
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      avatarUrl: normalizeAvatarUrl(rawAvatar),
      isProfileCompleteExplicit: json['is_profile_complete'] is bool
          ? json['is_profile_complete'] as bool
          : null,
      isEmailVerified: json['is_email_verified'] == true ||
          (json['email_verified_at'] != null &&
              json['email_verified_at'].toString().trim().isNotEmpty),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'gender': gender,
      'role': role,
      'avatar_url': avatarUrl,
      'is_profile_complete': isProfileComplete,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      username: username,
      phone: phone,
      gender: gender,
      role: role,
      avatarUrl: avatarUrl,
      isProfileCompleteExplicit: isProfileCompleteExplicit,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
    );
  }
}
