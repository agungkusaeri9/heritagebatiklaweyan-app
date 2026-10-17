import '../../domain/entities/user_entity.dart';

/// DTO Model Pengguna dengan serialization JSON dan mapping ke Entity
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.role,
    super.avatarUrl,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] != null
          ? json['id'].toString()
          : (json['_id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}'),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      avatarUrl: json['avatar_url']?.toString() ?? json['profile_photo_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      username: username,
      role: role,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }
}
