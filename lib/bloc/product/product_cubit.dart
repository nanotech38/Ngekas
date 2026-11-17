import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/product_service.dart';

class ProductFilter {
  final String query;
  final String? categoryId;

  const ProductFilter({this.query = '', this.categoryId});

  ProductFilter copyWith({String? query, String? Function()? categoryId}) {
    return ProductFilter(
      query: query ?? this.query,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
    );
  }
}

enum ProductStatus {
  initial,
  loading,
  loaded,
  streamError,
  addSuccess,
  addError,
  updateSuccess,
  updateError,
  deleteSuccess,
  deleteError,
}

class ProductState {
  final ProductStatus status;
  final List<ProductModel> all;
  final ProductFilter filter;
  final bool isSubmitting;
  final String errorMessage;
  final ProductModel? lastAdded;

  ProductState({
    required this.status,
    required this.all,
    required this.filter,
    required this.isSubmitting,
    required this.errorMessage,
    this.lastAdded,
  });

  ProductState.initial()
    : this(
        status: ProductStatus.initial,
        all: const [],
        filter: const ProductFilter(),
        isSubmitting: false,
        errorMessage: '',
      );

  ProductState copyWith({
    ProductStatus? status,
    List<ProductModel>? all,
    ProductFilter? filter,
    bool? isSubmitting,
    String? errorMessage,
    ProductModel? lastAdded,
  }) {
    return ProductState(
      status: status ?? this.status,
      all: all ?? this.all,
      filter: filter ?? this.filter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAdded: lastAdded ?? this.lastAdded,
    );
  }

  List<ProductModel> get filtered {
    return all.where((p) {
      if (filter.categoryId != null && p.categoryId != filter.categoryId) return false;
      return p.matchesQuery(filter.query);
    }).toList();
  }
}

class ProductCubit extends Cubit<ProductState> {
  static const tag = 'ProductCubit';

  StreamSubscription<List<ProductModel>>? _subscription;

  ProductCubit() : super(ProductState.initial());

  void watch() {
    AppLog.i(tag, 'watch: start');
    emit(state.copyWith(status: ProductStatus.loading));
    _subscription?.cancel();
    _subscription = ProductService.watch().listen(
      (products) => emit(state.copyWith(status: ProductStatus.loaded, all: products)),
      onError: (Object e) {
        AppLog.e(tag, 'watch: error', error: e);
        emit(state.copyWith(status: ProductStatus.streamError, errorMessage: e.toString()));
      },
    );
  }

  void setQuery(String query) => emit(state.copyWith(filter: state.filter.copyWith(query: query)));

  void setCategory(String? categoryId) =>
      emit(state.copyWith(filter: state.filter.copyWith(categoryId: () => categoryId)));

  Future<void> addProduct({
    required List<String> barcodes,
    required List<ProductPack> packs,
    required String name,
    required String categoryId,
    required String unit,
    required int buyPrice,
    required int sellPrice,
    required int stock,
  }) async {
    AppLog.i(tag, 'addProduct: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      final product = await ProductService.add(
        barcodes: barcodes,
        packs: packs,
        name: name,
        categoryId: categoryId,
        unit: unit,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
      );
      emit(state.copyWith(isSubmitting: false, status: ProductStatus.addSuccess, lastAdded: product));
      await _logActivity(
        ActivityAction.created,
        product,
        details: [
          ActivityDetail('Kategori', product.categoryName),
          ActivityDetail('Stok Awal', _stockText(product, product.stock)),
          ActivityDetail('Harga Jual', '${AppCurrency.format(product.sellPrice)} / ${product.unit}'),
          ActivityDetail('Barcode ${product.unit}', _barcodesText(product.barcodes)),
          for (final pack in product.packs)
            ActivityDetail('Kemasan ${pack.name}', '${pack.factor} ${product.unit} · ${_barcodesText(pack.barcodes)}'),
        ],
      );
    } catch (e, st) {
      AppLog.e(tag, 'addProduct: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: ProductStatus.addError, errorMessage: e.toString()));
    }
  }

  Future<void> updateProduct({
    required String id,
    required List<String> barcodes,
    required List<ProductPack> packs,
    required String name,
    required String categoryId,
    required String unit,
    required int buyPrice,
    required int sellPrice,
    required int stock,
    String stockReason = '',
    String stockNote = '',
  }) async {
    AppLog.i(tag, 'updateProduct: start');
    emit(state.copyWith(isSubmitting: true));
    final old = state.all.where((p) => p.id == id).firstOrNull;
    try {
      final updated = await ProductService.update(
        id: id,
        barcodes: barcodes,
        packs: packs,
        name: name,
        categoryId: categoryId,
        unit: unit,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
        stockReason: stockReason,
        stockNote: stockNote,
      );
      emit(state.copyWith(isSubmitting: false, status: ProductStatus.updateSuccess));
      await _logActivity(
        ActivityAction.updated,
        updated,
        details: [
          ..._changes(old, updated),
          if (old != null && old.stock != updated.stock) ...[
            ActivityDetail('Alasan Stok', stockReason),
            if (stockNote.trim().isNotEmpty) ActivityDetail('Catatan Stok', stockNote.trim()),
          ],
        ],
      );
    } catch (e, st) {
      AppLog.e(tag, 'updateProduct: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: ProductStatus.updateError, errorMessage: e.toString()));
    }
  }

  Future<void> deleteProduct({required String id, required String name}) async {
    AppLog.i(tag, 'deleteProduct: start');
    final old = state.all.where((p) => p.id == id).firstOrNull;
    try {
      await ProductService.delete(id: id);
      emit(state.copyWith(status: ProductStatus.deleteSuccess));
      if (old == null) {
        await ActivityLogService.log(
          action: ActivityAction.deleted,
          entity: ActivityEntity.product,
          subject: name,
          description: 'Barang: $name',
        );
      } else {
        await _logActivity(
          ActivityAction.deleted,
          old,
          details: [
            ActivityDetail('Kategori', old.categoryName),
            ActivityDetail('Sisa Stok', _stockText(old, old.stock)),
            ActivityDetail('Harga Jual', AppCurrency.format(old.sellPrice)),
          ],
        );
      }
    } catch (e, st) {
      AppLog.e(tag, 'deleteProduct: error', error: e, stackTrace: st);
      emit(state.copyWith(status: ProductStatus.deleteError, errorMessage: e.toString()));
    }
  }

  List<ActivityDetail> _changes(ProductModel? old, ProductModel now) {
    if (old == null) return [ActivityDetail('Stok', '${now.stock} ${now.unit}')];
    String price(int value) => value > 0 ? AppCurrency.format(value) : '-';
    String packsText(ProductModel p) =>
        p.packs.isEmpty ? '-' : p.packs.map((k) => '${k.name} ${k.factor} ${p.unit}').join(', ');
    String packBarcodes(ProductModel p) => p.packs.map((k) => k.barcodes.join('|')).join(';');
    return [
      if (old.name != now.name) ActivityDetail.change('Nama', old.name, now.name),
      if (old.stock != now.stock) ActivityDetail.change('Stok', _stockText(old, old.stock), _stockText(now, now.stock)),
      if (old.categoryName != now.categoryName) ActivityDetail.change('Kategori', old.categoryName, now.categoryName),
      if (old.sellPrice != now.sellPrice) ActivityDetail.change('Harga Jual', price(old.sellPrice), price(now.sellPrice)),
      if (old.unit != now.unit) ActivityDetail.change('Satuan', old.unit, now.unit),
      if (old.barcodes.join('|') != now.barcodes.join('|'))
        ActivityDetail.change('Barcode ${now.unit}', _barcodesText(old.barcodes), _barcodesText(now.barcodes)),
      if (packsText(old) != packsText(now)) ActivityDetail.change('Kemasan', packsText(old), packsText(now))
      else if (packBarcodes(old) != packBarcodes(now))
        ActivityDetail.change(
          'Barcode Kemasan',
          old.packs.map((k) => '${k.name}: ${_barcodesText(k.barcodes)}').join(', '),
          now.packs.map((k) => '${k.name}: ${_barcodesText(k.barcodes)}').join(', '),
        ),
    ];
  }

  static String _barcodesText(List<String> barcodes) => barcodes.isEmpty ? '-' : barcodes.join(', ');

  static String _stockText(ProductModel p, int qty) {
    final breakdown = p.packBreakdown(qty);
    return breakdown.isEmpty ? '$qty ${p.unit}' : '$qty ${p.unit} ($breakdown)';
  }

  Future<void> _logActivity(ActivityAction action, ProductModel product, {required List<ActivityDetail> details}) {
    final summary = details.isEmpty ? 'tidak ada perubahan data' : details.map((d) => d.summary).join(', ');
    return ActivityLogService.log(
      action: action,
      entity: ActivityEntity.product,
      subject: product.name,
      details: details,
      description: 'Barang: ${product.name} ($summary)',
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
