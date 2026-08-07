import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/app_user.dart';

class UserProfileException implements Exception {
  final String message;

  UserProfileException(this.message);

  @override
  String toString() => message;
}

// ─── UserProfileService ─────────────────────────────────────────────────────
//
// Wrapper ke koleksi Firestore /users/{uid} — profil workspace (role,
// ownerId) yang terpisah dari AuthService (yang khusus FirebaseAuth/kredensial
// akun). Static-only, sama pola dengan AuthService/AppValidator.
//
// Alur gabung workspace pakai kode undangan = uid owner-nya sendiri (bukan
// kode pendek terpisah) — supaya tidak perlu Cloud Functions/server buat
// generate & validasi kode, cukup Firestore + Auth client-side yang sudah
// ada. /owner_codes/{ownerId} cuma penanda publik "uid ini valid owner",
// dipakai calon staff buat validasi kode SEBELUM profil staff-nya dibuat
// (lihat AuthCubit.register).

class UserProfileService {
  UserProfileService._();

  static const tag = 'UserProfileService';

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  static CollectionReference<Map<String, dynamic>> get _ownerCodes =>
      FirebaseFirestore.instance.collection('owner_codes');

  static Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      AppLog.w(tag, 'fetchProfile: profil $uid tidak ditemukan');
      return null;
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  // Dipanggil sekali setelah register sukses tanpa kode undangan — jadi
  // owner workspace baru (ownerId == uid miliknya sendiri). Sekalian bikin
  // /owner_codes/{uid} supaya uid ini bisa dipakai sebagai kode undangan.
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
    await _ownerCodes.doc(uid).set({'createdAt': Timestamp.now()});
    AppLog.i(tag, 'createOwnerProfile: $uid');
    return user;
  }

  // Dipanggil saat register PAKAI kode undangan — cek dulu (lewat
  // verifyInviteCode) sebelum ini dipanggil.
  static Future<AppUser> createStaffProfile({
    required String uid,
    required String email,
    required String ownerId,
  }) async {
    final user = AppUser(
      uid: uid,
      email: email,
      role: UserRole.staff,
      ownerId: ownerId,
    );
    await _users.doc(uid).set(user.toMap());
    AppLog.i(tag, 'createStaffProfile: $uid -> owner $ownerId');
    return user;
  }

  // Kode undangan = uid owner. Valid kalau /owner_codes/{code} ada.
  static Future<bool> verifyInviteCode(String code) async {
    final doc = await _ownerCodes.doc(code).get();
    return doc.exists;
  }

  // Dipakai layar "Kelola Orang" (owner-only) — semua profil yang
  // ownerId-nya cocok, termasuk owner itu sendiri.
  static Stream<List<AppUser>> watchWorkspaceMembers(String ownerId) {
    return _users.where('ownerId', isEqualTo: ownerId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  // "Keluarkan" orang dari workspace — cuma hapus profil /users/{uid},
  // akun FirebaseAuth-nya sendiri tetap ada (tidak bisa dihapus dari client
  // tanpa Admin SDK/Cloud Functions). Login berikutnya bakal ditolak balik
  // ke LoginScreen karena fetchProfile jadi null (lihat AuthCubit.login).
  static Future<void> removeMember(String uid) async {
    try {
      await _users.doc(uid).delete();
      AppLog.i(tag, 'removeMember: $uid');
    } catch (e, st) {
      AppLog.e(tag, 'removeMember: error', error: e, stackTrace: st);
      throw UserProfileException(_mapError(e));
    }
  }

  static String _mapError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Kamu tidak punya izin untuk melakukan ini';
    }
    return 'Terjadi kesalahan, silakan coba lagi';
  }
}
