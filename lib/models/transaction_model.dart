// ─── TransactionModel ───────────────────────────────────────────────────────
//
// Satu baris transaksi barang:
// - sale     -> Penjualan (barang keluar, stok berkurang)
// - purchase -> Pembelian Stok (barang masuk, stok bertambah)
//
// itemName/categoryName didenormalisasi (disalin saat transaksi dibuat)
// supaya riwayat tetap terbaca walau barangnya kemudian diubah/dihapus.
// `amount` = quantity × unitPrice. `invoiceNo` = nomor nota penjualan dari
// Kasir; beberapa baris barang dalam satu pembayaran berbagi nomor yang sama
// (kosong untuk Pembelian Stok).

enum TransactionType { sale, purchase }

extension TransactionTypeLabel on TransactionType {
  String get label => this == TransactionType.sale ? 'Penjualan' : 'Pembelian Stok';
}

class TransactionModel {
  final String id;
  final String invoiceNo;
  final TransactionType type;
  final String productId;
  final String itemName;
  final String categoryId;
  final String categoryName;
  final int quantity;
  final int unitPrice;
  final DateTime date;
  final String note;
  final String actorName;

  const TransactionModel({
    required this.id,
    this.invoiceNo = '',
    required this.type,
    required this.productId,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.quantity,
    required this.unitPrice,
    required this.date,
    required this.note,
    required this.actorName,
  });

  int get amount => quantity * unitPrice;

  // Kunci pengelompokan nota — baris tanpa nomor nota jadi nota sendiri.
  String get invoiceKey => invoiceNo.isNotEmpty ? invoiceNo : id;
}
