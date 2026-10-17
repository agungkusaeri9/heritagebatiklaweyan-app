/// Domain Entity untuk data Pengguna (Pure business object, tanpa dependencies framework)
class UserEntity {
  final String id;
  final String email;
  final String username;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

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
