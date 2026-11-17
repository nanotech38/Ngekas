enum TransactionType { sale, purchase }

extension TransactionTypeLabel on TransactionType {
  String get label => this == TransactionType.sale ? 'Penjualan' : 'Pembelian Stok';
}

class TransactionModel {
  final String id;
  final String invoiceNo;
  final TransactionType type;
  final String productId;
  // itemName & categoryName disalin pas transaksi dibuat, biar riwayat tetap
  // kebaca walau barangnya diedit/dihapus
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

  String get invoiceKey => invoiceNo.isNotEmpty ? invoiceNo : id;
}
