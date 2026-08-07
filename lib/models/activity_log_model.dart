import 'package:cloud_firestore/cloud_firestore.dart';

// ─── ActivityLogModel ───────────────────────────────────────────────────────
//
// Satu entri Riwayat Aktivitas — dicatat tiap kali user menambah/mengubah/
// menghapus laporan atau kategori, disimpan di
// /workspaces/{ownerId}/activity_logs. `description` sudah berisi ringkasan
// siap tampil (mis. nama kategori + nominal) supaya layar Riwayat Aktivitas
// tidak perlu lookup balik ke koleksi transactions/categories yang datanya
// mungkin sudah berubah atau terhapus.

enum ActivityAction { created, updated, deleted }

enum ActivityEntity { transaction, category, member }

class ActivityLogModel {
  final String id;
  final String actorEmail;
  final ActivityAction action;
  final ActivityEntity entity;
  final String description;
  final DateTime timestamp;

  const ActivityLogModel({
    required this.id,
    required this.actorEmail,
    required this.action,
    required this.entity,
    required this.description,
    required this.timestamp,
  });

  factory ActivityLogModel.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLogModel(
      id: id,
      actorEmail: map['actorEmail'] as String? ?? '-',
      action: ActivityAction.values.firstWhere(
        (a) => a.name == map['action'],
        orElse: () => ActivityAction.created,
      ),
      entity: ActivityEntity.values.firstWhere(
        (e) => e.name == map['entity'],
        orElse: () => ActivityEntity.transaction,
      ),
      description: map['description'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
