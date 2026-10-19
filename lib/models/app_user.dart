// ─── AppUser ────────────────────────────────────────────────────────────────
//
// Profil user yang sedang login. Data akun (termasuk password) disimpan di
// DatabaseService (in-memory, hardcode) — AppUser sendiri sengaja tidak
// membawa password supaya aman dioper ke layar mana pun.
//
// Dua role:
// - admin -> akses penuh (barang, kategori, stok masuk, hapus transaksi,
//   kelola pengguna).
// - kasir -> fokus ke transaksi penjualan (Kasir) & melihat stok.

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
