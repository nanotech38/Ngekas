import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/models/transaction_model.dart';

// ─── Periode laporan ────────────────────────────────────────────────────────

enum ReportPeriod { daily, monthly, custom }

extension ReportPeriodLabel on ReportPeriod {
  String get label => switch (this) {
    ReportPeriod.daily => 'Harian',
    ReportPeriod.monthly => 'Bulanan',
    ReportPeriod.custom => 'Pilih Tanggal',
  };
}

// Rentang tanggal laporan (inklusif per hari), lengkap dengan label tanggal
// pasti untuk layar & PDF.
class ReportRange {
  final ReportPeriod period;
  final DateTime start;
  final DateTime end;

  const ReportRange._(this.period, this.start, this.end);

  factory ReportRange.daily(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return ReportRange._(ReportPeriod.daily, d, d);
  }

  factory ReportRange.monthly(DateTime anyDay) {
    return ReportRange._(
      ReportPeriod.monthly,
      DateTime(anyDay.year, anyDay.month, 1),
      DateTime(anyDay.year, anyDay.month + 1, 0),
    );
  }

  factory ReportRange.custom(DateTime start, DateTime end) {
    return ReportRange._(
      ReportPeriod.custom,
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day),
    );
  }

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  String get label => switch (period) {
    ReportPeriod.daily => AppDate.format(start),
    ReportPeriod.monthly => AppDate.monthYear(start),
    ReportPeriod.custom => start == end ? AppDate.format(start) : '${AppDate.format(start)} - ${AppDate.format(end)}',
  };
}

// ─── Hasil laporan ──────────────────────────────────────────────────────────

// Satu nota penjualan = beberapa baris transaksi dengan nomor nota yang sama.
class SalesInvoice {
  final String key;
  final String invoiceNo;
  final DateTime date;
  final String actorName;
  final String note;
  final List<TransactionModel> lines;

  const SalesInvoice({
    required this.key,
    required this.invoiceNo,
    required this.date,
    required this.actorName,
    required this.note,
    required this.lines,
  });

  int get total => lines.fold(0, (sum, t) => sum + t.amount);
  int get quantity => lines.fold(0, (sum, t) => sum + t.quantity);
  String get displayNo => invoiceNo.isNotEmpty ? invoiceNo : 'Tanpa nota';
}

class SalesDayGroup {
  final DateTime day;
  final List<SalesInvoice> invoices;

  const SalesDayGroup({required this.day, required this.invoices});

  int get total => invoices.fold(0, (sum, i) => sum + i.total);
}

class ProductRecap {
  final String productId;
  final String name;
  final String categoryName;
  final int quantity;
  final int revenue;

  const ProductRecap({
    required this.productId,
    required this.name,
    required this.categoryName,
    required this.quantity,
    required this.revenue,
  });
}

class SalesSummary {
  final int revenue;
  final int invoiceCount;
  final int quantity;
  // Laba kotor = (harga jual - harga beli) × jumlah, hanya untuk barang yang
  // harga belinya diisi. `profitComplete` false kalau ada barang tanpa harga
  // beli (labanya jadi tidak lengkap).
  final int grossProfit;
  final bool hasProfitData;
  final bool profitComplete;

  const SalesSummary({
    required this.revenue,
    required this.invoiceCount,
    required this.quantity,
    required this.grossProfit,
    required this.hasProfitData,
    required this.profitComplete,
  });

  int get averagePerInvoice => invoiceCount == 0 ? 0 : (revenue / invoiceCount).round();
}

// ─── SalesReport ────────────────────────────────────────────────────────────
//
// Mengolah baris transaksi penjualan (yang sudah difilter) jadi: daftar nota,
// nota dikelompokkan per tanggal, rekap per barang, dan ringkasan. Dipakai
// bareng oleh layar Laporan Penjualan & export PDF supaya angkanya sama.

class SalesReport {
  final List<SalesInvoice> invoices;
  final List<SalesDayGroup> days;
  final List<ProductRecap> products;
  final SalesSummary summary;

  const SalesReport._({required this.invoices, required this.days, required this.products, required this.summary});

  factory SalesReport.build(List<TransactionModel> lines, Map<String, ProductModel> productsById) {
    // Nota
    final byKey = <String, List<TransactionModel>>{};
    for (final t in lines) {
      byKey.putIfAbsent(t.invoiceKey, () => []).add(t);
    }
    final invoices = byKey.entries.map((e) {
      final first = e.value.first;
      return SalesInvoice(
        key: e.key,
        invoiceNo: first.invoiceNo,
        date: first.date,
        actorName: first.actorName,
        note: first.note,
        lines: e.value,
      );
    }).toList()
      // Terbaru dulu; kalau jamnya sama persis, nomor nota yang lebih besar
      // (dibuat belakangan) di atas.
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.invoiceNo.compareTo(a.invoiceNo);
      });

    // Per tanggal (urutan nota di dalamnya ikut terbaru dulu)
    final byDay = <DateTime, List<SalesInvoice>>{};
    for (final invoice in invoices) {
      final day = DateTime(invoice.date.year, invoice.date.month, invoice.date.day);
      byDay.putIfAbsent(day, () => []).add(invoice);
    }
    final days = byDay.entries.map((e) => SalesDayGroup(day: e.key, invoices: e.value)).toList()
      ..sort((a, b) => b.day.compareTo(a.day));

    // Per barang
    final recapMap = <String, ProductRecap>{};
    for (final t in lines) {
      final current = recapMap[t.productId];
      recapMap[t.productId] = ProductRecap(
        productId: t.productId,
        name: t.itemName,
        categoryName: t.categoryName,
        quantity: (current?.quantity ?? 0) + t.quantity,
        revenue: (current?.revenue ?? 0) + t.amount,
      );
    }
    final recaps = recapMap.values.toList()
      ..sort((a, b) {
        final byQuantity = b.quantity.compareTo(a.quantity);
        return byQuantity != 0 ? byQuantity : b.revenue.compareTo(a.revenue);
      });

    // Ringkasan
    var profit = 0;
    var coveredLines = 0;
    for (final t in lines) {
      final product = productsById[t.productId];
      if (product == null || !product.hasBuyPrice) continue;
      profit += (t.unitPrice - product.buyPrice) * t.quantity;
      coveredLines++;
    }

    return SalesReport._(
      invoices: invoices,
      days: days,
      products: recaps,
      summary: SalesSummary(
        revenue: lines.fold(0, (sum, t) => sum + t.amount),
        invoiceCount: invoices.length,
        quantity: lines.fold(0, (sum, t) => sum + t.quantity),
        grossProfit: profit,
        hasProfitData: coveredLines > 0,
        profitComplete: coveredLines == lines.length,
      ),
    );
  }
}
