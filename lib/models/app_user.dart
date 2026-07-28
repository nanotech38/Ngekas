// ─── AppUser ────────────────────────────────────────────────────────────────
//
// Profil user dari Firestore (/users/{uid}) — beda dengan FirebaseAuth's
// User yang cuma punya info akun (email, uid). AppUser nambahin konsep
// workspace: role (owner/staff) dan ownerId (workspace mana yang diakses).
// Untuk owner, ownerId == uid milik sendiri.

enum UserRole { owner, staff }

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String ownerId;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.ownerId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      role: (map['role'] as String?) == 'staff'
          ? UserRole.staff
          : UserRole.owner,
      ownerId: map['ownerId'] as String? ?? uid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role == UserRole.owner ? 'owner' : 'staff',
      'ownerId': ownerId,
    };
  }
}
