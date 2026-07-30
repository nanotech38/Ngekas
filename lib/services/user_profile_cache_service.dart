import 'dart:convert';

import 'package:ngekas/models/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── UserProfileCacheService ────────────────────────────────────────────────
//
// Cache lokal profil user (role/ownerId) di SharedPreferences supaya
// auto-login tidak perlu fetch ulang ke Firestore tiap kali app dibuka.
// Cache dicocokkan lewat uid — kalau device dipakai akun lain, cache lama
// otomatis dianggap tidak valid (lihat pemakaian di AuthCubit.loadCurrentProfile).

class UserProfileCacheService {
  UserProfileCacheService._();

  static const _key = 'cached_user_profile';

  static Future<AppUser?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final uid = map['uid'] as String?;
    if (uid == null) return null;

    return AppUser.fromMap(uid, map);
  }

  static Future<void> saveProfile(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'uid': user.uid, ...user.toMap()}));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
