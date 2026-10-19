// ─── ActivityLogModel ───────────────────────────────────────────────────────
//
// Satu entri Riwayat Aktivitas — dicatat tiap kali user menambah/mengubah/
// menghapus transaksi, barang, kategori, atau anggota. Semua isinya sudah
// siap tampil (bukan id) supaya layar Riwayat Aktivitas tidak perlu lookup
// balik ke data yang mungkin sudah berubah atau terhapus:
// - `subject`: nama yang dikenai aksi (nama barang, No. Nota, @username).
// - `details`: rincian per baris; kalau `oldValue` diisi berarti baris itu
//   perubahan (lama -> baru).
// - `description`: ringkasan satu kalimat (dipakai pencarian & data lama
//   yang belum punya `details`).

enum ActivityAction { created, updated, deleted }

enum ActivityEntity { transaction, product, category, member }

class ActivityDetail {
  final String label;
  final String value;
  final String? oldValue;

  const ActivityDetail(this.label, this.value, {this.oldValue});

  // Baris perubahan "lama -> baru".
  const ActivityDetail.change(this.label, String from, String to) : value = to, oldValue = from;

  bool get isChange => oldValue != null;

  String get summary => isChange ? '$label: $oldValue → $value' : '$label: $value';
}

class ActivityLogModel {
  final String id;
  final String actorName;
  final String actorRole;
  final ActivityAction action;
  final ActivityEntity entity;
  final String subject;
  final List<ActivityDetail> details;
  final String description;
  final DateTime timestamp;

  const ActivityLogModel({
    required this.id,
    required this.actorName,
    this.actorRole = '',
    required this.action,
    required this.entity,
    this.subject = '',
    this.details = const [],
    required this.description,
    required this.timestamp,
  });

  // Teks yang dicari lewat kolom pencarian.
  String get searchText =>
      [actorName, subject, description, for (final d in details) d.summary].join(' ').toLowerCase();
}
