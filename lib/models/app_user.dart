enum UserRole { admin, kasir }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.admin ? 'Admin' : 'Kasir';
}

class AppUser {
  final String uid;
  final String username;
  final String name;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.username,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
}
