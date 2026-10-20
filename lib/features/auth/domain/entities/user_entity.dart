/// Domain Entity untuk data Pengguna (Pure business object, tanpa dependencies framework)
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? phone;
  final String? gender;
  final String role;
  final String? avatarUrl;
  final bool? isProfileCompleteExplicit;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.phone,
    this.gender,
    required this.role,
    this.avatarUrl,
    this.isProfileCompleteExplicit,
    required this.createdAt,
  });

  /// Status kelengkapan profil (berdasarkan flag backend atau kelengkapan field wajib)
  bool get isProfileComplete {
    if (isProfileCompleteExplicit != null) {
      return isProfileCompleteExplicit!;
    }
    return name.trim().isNotEmpty &&
        (phone != null && phone!.trim().isNotEmpty) &&
        (gender != null && gender!.trim().isNotEmpty);
  }

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? phone,
    String? gender,
    String? role,
    String? avatarUrl,
    bool? isProfileCompleteExplicit,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isProfileCompleteExplicit:
          isProfileCompleteExplicit ?? this.isProfileCompleteExplicit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ username.hashCode;
}
