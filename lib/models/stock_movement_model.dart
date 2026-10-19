// ─── StockMovementModel ─────────────────────────────────────────────────────
//
// Satu baris kartu stok: setiap perubahan stok barang (stok awal, penjualan,
// stok masuk, penyesuaian) dicatat lengkap dengan saldo sesudahnya, alasan,
// siapa & kapan. Jumlah selalu dalam satuan dasar barang. Nama & satuan
// barang didenormalisasi supaya kartu stok tetap terbaca walau barangnya
// sudah diubah/dihapus.

enum StockMovementType { initial, sale, purchase, adjustment }

extension StockMovementTypeLabel on StockMovementType {
  String get label => switch (this) {
    StockMovementType.initial => 'Stok Awal',
    StockMovementType.sale => 'Penjualan',
    StockMovementType.purchase => 'Stok Masuk',
    StockMovementType.adjustment => 'Penyesuaian',
  };
}

// Alasan perubahan stok lewat form Ubah Barang (wajib dipilih kalau stok
// diubah).
enum StockAdjustReason { incoming, opname, damaged, lost, returned, other }

extension StockAdjustReasonLabel on StockAdjustReason {
  String get label => switch (this) {
    StockAdjustReason.incoming => 'Barang Datang',
    StockAdjustReason.opname => 'Stock Opname',
    StockAdjustReason.damaged => 'Barang Rusak',
    StockAdjustReason.lost => 'Barang Hilang',
    StockAdjustReason.returned => 'Retur ke Supplier',
    StockAdjustReason.other => 'Lainnya',
  };
}

class StockMovementModel {
  final String id;
  final String productId;
  final String productName;
  final String unit;
  final StockMovementType type;
  // Positif = masuk, negatif = keluar.
  final int change;
  // Saldo stok setelah perubahan ini.
  final int balance;
  final String reason;
  final String note;
  // Nomor referensi, mis. No. Nota penjualan.
  final String refNo;
  final String actorName;
  final DateTime date;

  const StockMovementModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.type,
    required this.change,
    required this.balance,
    this.reason = '',
    this.note = '',
    this.refNo = '',
    required this.actorName,
    required this.date,
  });

  bool get isIncoming => change > 0;

  // Judul baris: alasan penyesuaian kalau ada, selain itu jenisnya.
  String get title => reason.isNotEmpty ? reason : type.label;
}
