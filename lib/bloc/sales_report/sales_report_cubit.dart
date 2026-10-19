import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/product_service.dart';
import 'package:ngekas/services/transaction_service.dart';

enum SalesReportStatus { loading, loaded }

class SalesReportState {
  final SalesReportStatus status;
  final List<TransactionModel> sales;
  final Map<String, ProductModel> products;
  final ReportRange range;
  final String query;
  final String? categoryId;
  final String? cashierName;
  final String errorMessage;

  const SalesReportState({
    required this.status,
    required this.sales,
    required this.products,
    required this.range,
    required this.query,
    required this.categoryId,
    required this.cashierName,
    required this.errorMessage,
  });

  SalesReportState.initial()
    : this(
        status: SalesReportStatus.loading,
        sales: const [],
        products: const {},
        range: ReportRange.daily(DateTime.now()),
        query: '',
        categoryId: null,
        cashierName: null,
        errorMessage: '',
      );

  SalesReportState copyWith({
    SalesReportStatus? status,
    List<TransactionModel>? sales,
    Map<String, ProductModel>? products,
    ReportRange? range,
    String? query,
    String? Function()? categoryId,
    String? Function()? cashierName,
    String? errorMessage,
  }) {
    return SalesReportState(
      status: status ?? this.status,
      sales: sales ?? this.sales,
      products: products ?? this.products,
      range: range ?? this.range,
      query: query ?? this.query,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      cashierName: cashierName != null ? cashierName() : this.cashierName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get hasExtraFilter => categoryId != null || cashierName != null;

  // Nama kasir yang pernah tercatat di penjualan, untuk pilihan filter.
  List<String> get cashierNames => {for (final t in sales) t.actorName}.toList()..sort();

  // Boleh maju ke periode berikutnya selama belum melewati hari ini.
  bool get canGoNext {
    final now = DateTime.now();
    return range.end.isBefore(DateTime(now.year, now.month, now.day));
  }

  List<TransactionModel> get filteredLines {
    final inRange = sales.where((t) {
      if (!range.contains(t.date)) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (cashierName != null && t.actorName != cashierName) return false;
      return true;
    }).toList();

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return inRange;
    // Cari per nota: kalau salah satu barang / nomor notanya cocok, satu nota
    // ditampilkan utuh.
    final matchedKeys = {
      for (final t in inRange)
        if (t.invoiceNo.toLowerCase().contains(q) || t.itemName.toLowerCase().contains(q)) t.invoiceKey,
    };
    return inRange.where((t) => matchedKeys.contains(t.invoiceKey)).toList();
  }

  SalesReport get report => SalesReport.build(filteredLines, products);
}

// ─── SalesReportCubit ───────────────────────────────────────────────────────
//
// State layar Laporan Penjualan: data penjualan + barang (untuk laba kotor),
// periode (Harian / Bulanan / custom), pencarian, serta filter kategori &
// kasir.

class SalesReportCubit extends Cubit<SalesReportState> {
  static const tag = 'SalesReportCubit';

  StreamSubscription<List<TransactionModel>>? _salesSubscription;
  StreamSubscription<List<ProductModel>>? _productSubscription;

  SalesReportCubit() : super(SalesReportState.initial());

  void watch() {
    AppLog.i(tag, 'watch: start');
    _salesSubscription?.cancel();
    _productSubscription?.cancel();
    _salesSubscription = TransactionService.watch().listen((all) {
      final sales = all.where((t) => t.type == TransactionType.sale).toList();
      emit(state.copyWith(status: SalesReportStatus.loaded, sales: sales));
    });
    _productSubscription = ProductService.watch().listen((products) {
      emit(state.copyWith(products: {for (final p in products) p.id: p}));
    });
  }

  void setPeriod(ReportPeriod period) {
    final now = DateTime.now();
    final range = switch (period) {
      ReportPeriod.daily => ReportRange.daily(now),
      ReportPeriod.monthly => ReportRange.monthly(now),
      ReportPeriod.custom => state.range,
    };
    emit(state.copyWith(range: range, status: SalesReportStatus.loaded));
  }

  void setCustomRange(DateTime start, DateTime end) {
    emit(state.copyWith(range: ReportRange.custom(start, end), status: SalesReportStatus.loaded));
  }

  // Mundur (-1) / maju (+1) satu hari atau satu bulan.
  void shift(int step) {
    final range = state.range;
    final next = switch (range.period) {
      ReportPeriod.daily => ReportRange.daily(DateTime(range.start.year, range.start.month, range.start.day + step)),
      ReportPeriod.monthly => ReportRange.monthly(DateTime(range.start.year, range.start.month + step, 1)),
      ReportPeriod.custom => range,
    };
    emit(state.copyWith(range: next, status: SalesReportStatus.loaded));
  }

  void setQuery(String query) => emit(state.copyWith(query: query, status: SalesReportStatus.loaded));

  void setFilter({String? categoryId, String? cashierName}) {
    emit(
      state.copyWith(
        categoryId: () => categoryId,
        cashierName: () => cashierName,
        status: SalesReportStatus.loaded,
      ),
    );
  }

  @override
  Future<void> close() {
    _salesSubscription?.cancel();
    _productSubscription?.cancel();
    return super.close();
  }
}
