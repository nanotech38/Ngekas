import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/stock_movement_model.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/database_service.dart';

// record() dipanggil SETELAH stok barang diupdate, jadi saldo = product.stock
class StockMovementService {
  StockMovementService._();

  static DatabaseService get _db => DatabaseService.instance;

  static void record({
    required ProductModel product,
    required StockMovementType type,
    required int change,
    String reason = '',
    String note = '',
    String refNo = '',
    DateTime? date,
  }) {
    if (change == 0 && type != StockMovementType.initial) return;
    _db.stockMovements.insert(
      StockMovementModel(
        id: _db.newId('m'),
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        type: type,
        change: change,
        balance: product.stock,
        reason: reason,
        note: note,
        refNo: refNo,
        actorName: AuthService.currentUser?.name ?? '-',
        date: date ?? DateTime.now(),
      ),
    );
  }

  static Stream<List<StockMovementModel>> watchFor(String productId) {
    return _db.stockMovements.watch().map((rows) => _sorted(rows.where((m) => m.productId == productId)));
  }

  static List<StockMovementModel> _sorted(Iterable<StockMovementModel> rows) {
    int seq(StockMovementModel m) => int.tryParse(m.id.split('-').last) ?? 0;
    return rows.toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : seq(b).compareTo(seq(a));
      });
  }
}
