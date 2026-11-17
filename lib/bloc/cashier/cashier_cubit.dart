import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/cart_item_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/transaction_service.dart';

enum CashierStatus { idle, checkoutSuccess, checkoutError }

class CashierState {
  final List<CartItem> items;
  final CashierStatus status;
  final bool isSubmitting;
  final String errorMessage;
  final String lastInvoiceNo;
  final int lastTotal;

  const CashierState({
    required this.items,
    required this.status,
    required this.isSubmitting,
    required this.errorMessage,
    required this.lastInvoiceNo,
    required this.lastTotal,
  });

  const CashierState.initial()
    : this(
        items: const [],
        status: CashierStatus.idle,
        isSubmitting: false,
        errorMessage: '',
        lastInvoiceNo: '',
        lastTotal: 0,
      );

  CashierState copyWith({
    List<CartItem>? items,
    CashierStatus? status,
    bool? isSubmitting,
    String? errorMessage,
    String? lastInvoiceNo,
    int? lastTotal,
  }) {
    return CashierState(
      items: items ?? this.items,
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      lastInvoiceNo: lastInvoiceNo ?? this.lastInvoiceNo,
      lastTotal: lastTotal ?? this.lastTotal,
    );
  }

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  int quantityOf(String productId) => items.where((i) => i.product.id == productId).firstOrNull?.quantity ?? 0;
}

class CashierCubit extends Cubit<CashierState> {
  static const tag = 'CashierCubit';

  CashierCubit() : super(const CashierState.initial());

  bool add(ProductModel product) {
    final current = state.quantityOf(product.id);
    if (current + 1 > product.stock) return false;
    _setQuantity(product, current + 1);
    return true;
  }

  bool setQuantity(ProductModel product, int quantity) {
    if (quantity > product.stock) return false;
    _setQuantity(product, quantity);
    return true;
  }

  void decrement(ProductModel product) => _setQuantity(product, state.quantityOf(product.id) - 1);

  void remove(ProductModel product) => _setQuantity(product, 0);

  void clear() => emit(state.copyWith(items: const [], status: CashierStatus.idle));

  void syncProducts(List<ProductModel> products) {
    // lagi checkout, stoknya memang sedang dikurangi. jangan ikut motong keranjang
    if (state.items.isEmpty || state.isSubmitting) return;
    final synced = <CartItem>[];
    for (final item in state.items) {
      final latest = products.where((p) => p.id == item.product.id).firstOrNull;
      if (latest == null || latest.stock <= 0) continue;
      synced.add(CartItem(product: latest, quantity: item.quantity.clamp(1, latest.stock)));
    }
    emit(state.copyWith(items: synced, status: CashierStatus.idle));
  }

  void _setQuantity(ProductModel product, int quantity) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (quantity <= 0) {
      if (index != -1) items.removeAt(index);
    } else if (index == -1) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      items[index] = items[index].copyWith(product: product, quantity: quantity);
    }
    emit(state.copyWith(items: items, status: CashierStatus.idle));
  }

  Future<void> checkout({required String note}) async {
    AppLog.i(tag, 'checkout: start');
    emit(state.copyWith(isSubmitting: true, status: CashierStatus.idle));
    try {
      final total = state.total;
      final itemCount = state.totalQuantity;
      final items = state.items;
      final invoiceNo = await TransactionService.checkout(items: items, note: note);
      emit(
        state.copyWith(
          items: const [],
          isSubmitting: false,
          status: CashierStatus.checkoutSuccess,
          lastInvoiceNo: invoiceNo,
          lastTotal: total,
        ),
      );
      await ActivityLogService.log(
        action: ActivityAction.created,
        entity: ActivityEntity.transaction,
        subject: invoiceNo,
        details: [
          const ActivityDetail('Jenis', 'Penjualan (Kasir)'),
          for (final item in items)
            ActivityDetail(
              item.product.name,
              '${item.quantity} x ${AppCurrency.format(item.product.sellPrice)} = ${AppCurrency.format(item.subtotal)}',
            ),
          ActivityDetail('Total', '${AppCurrency.format(total)} ($itemCount item)'),
          if (note.trim().isNotEmpty) ActivityDetail('Catatan', note.trim()),
        ],
        description: 'Penjualan Kasir $invoiceNo: $itemCount item (${AppCurrency.format(total)})',
      );
    } catch (e, st) {
      AppLog.e(tag, 'checkout: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: CashierStatus.checkoutError, errorMessage: e.toString()));
    }
  }
}
