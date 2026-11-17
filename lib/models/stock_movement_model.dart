enum StockMovementType { initial, sale, purchase, adjustment }

extension StockMovementTypeLabel on StockMovementType {
  String get label => switch (this) {
    StockMovementType.initial => 'Stok Awal',
    StockMovementType.sale => 'Penjualan',
    StockMovementType.purchase => 'Stok Masuk',
    StockMovementType.adjustment => 'Penyesuaian',
  };
}

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
  final int change;
  final int balance;
  final String reason;
  final String note;
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

  String get title => reason.isNotEmpty ? reason : type.label;
}
