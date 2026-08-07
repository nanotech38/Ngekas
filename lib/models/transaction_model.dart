import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngekas/models/category_model.dart';

// ─── TransactionModel ───────────────────────────────────────────────────────
//
// Satu entri pemasukan/pengeluaran di Laporan. categoryName didenormalisasi
// (disalin saat entri dibuat) supaya kartu di list tidak perlu lookup
// terpisah ke koleksi categories tiap render.

class TransactionModel {
  final String id;
  final CategoryType type;
  final String categoryId;
  final String categoryName;
  final String itemName;
  final int quantity;
  final int amount;
  final DateTime date;
  final String note;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.itemName,
    required this.quantity,
    required this.amount,
    required this.date,
    required this.note,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      type: (map['type'] as String?) == 'expense' ? CategoryType.expense : CategoryType.income,
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '-',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }
}
