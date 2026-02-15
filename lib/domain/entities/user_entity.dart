class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? profilePhotoUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool notificationsEnabled;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.profilePhotoUrl,
    this.createdAt,
    this.lastLogin,
    required this.notificationsEnabled,
  });
}
