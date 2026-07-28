import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/app_user.dart';

// ─── UserProfileService ─────────────────────────────────────────────────────
//
// Wrapper ke koleksi Firestore /users/{uid} — profil workspace (role,
// ownerId) yang terpisah dari AuthService (yang khusus FirebaseAuth/kredensial
// akun). Static-only, sama pola dengan AuthService/AppValidator.

class UserProfileService {
  UserProfileService._();

  static const tag = 'UserProfileService';

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  static Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      AppLog.w(tag, 'fetchProfile: profil $uid tidak ditemukan');
      return null;
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  // Dipanggil sekali setelah register sukses. Belum ada alur undang-staff,
  // jadi setiap akun yang daftar sendiri otomatis jadi owner workspace-nya
  // sendiri (ownerId == uid miliknya).
  static Future<AppUser> createOwnerProfile({
    required String uid,
    required String email,
  }) async {
    final user = AppUser(
      uid: uid,
      email: email,
      role: UserRole.owner,
      ownerId: uid,
    );
    await _users.doc(uid).set(user.toMap());
    AppLog.i(tag, 'createOwnerProfile: $uid');
    return user;
  }
}
