import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/product_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/product_service.dart';

// ─── ProductImportService ───────────────────────────────────────────────────
//
// Import data barang massal dari tabel (hasil SpreadsheetReader). Alurnya:
// 1. `parse()` — cocokkan kolom dari baris judul, validasi tiap baris, dan
//    tandai statusnya (siap / dilewati / error) TANPA mengubah data.
// 2. Layar pratinjau menampilkan hasilnya.
// 3. `commit()` — simpan baris yang siap: kategori baru dibuat otomatis,
//    stok awal tercatat di kartu stok, satu catatan di Riwayat Aktivitas.
//
// Kolom (urutan bebas, huruf besar/kecil bebas):
//   Nama*, Kategori*, Satuan*, Harga Jual*, Stok, Barcode, Kemasan,
//   Isi Kemasan, Barcode Kemasan
// Barcode lebih dari satu dipisah "|" (mis. 899111|899222).

enum ImportRowStatus { ready, skipped, error }

class ImportRow {
  final int line;
  final String name;
  final String categoryName;
  final String unit;
  final int sellPrice;
  final int stock;
  final List<String> barcodes;
  final String packName;
  final int packFactor;
  final List<String> packBarcodes;
  ImportRowStatus status;
  String message;

  ImportRow({
    required this.line,
    required this.name,
    required this.categoryName,
    required this.unit,
    required this.sellPrice,
    required this.stock,
    required this.barcodes,
    required this.packName,
    required this.packFactor,
    required this.packBarcodes,
    this.status = ImportRowStatus.ready,
    this.message = '',
  });

  bool get hasPack => packName.isNotEmpty;
}

class ImportResult {
  final int created;
  final int newCategories;
  final int skipped;

  const ImportResult({required this.created, required this.newCategories, required this.skipped});
}

class ProductImportService {
  ProductImportService._();

  static const tag = 'ProductImportService';

  static DatabaseService get _db => DatabaseService.instance;

  static const _columns = {
    'nama': ['nama', 'namabarang', 'namaitem', 'barang', 'item'],
    'kategori': ['kategori', 'category'],
    'satuan': ['satuan', 'satuandasar', 'unit'],
    'harga': ['hargajual', 'harga', 'price'],
    'stok': ['stok', 'stock', 'stokawal', 'jumlah', 'qty'],
    'barcode': ['barcode', 'barcodesatuan'],
    'kemasan': ['kemasan', 'satuankemasan'],
    'isi': ['isikemasan', 'isi'],
    'barcodekemasan': ['barcodekemasan', 'barcodedus'],
  };
  static const _required = ['nama', 'kategori', 'satuan', 'harga'];

  static String _normalize(String header) => header.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

  // Isi template CSV ("sep=," supaya Excel langsung memisah kolom).
  static String templateCsv() => [
    'sep=,',
    'Nama,Kategori,Satuan,Harga Jual,Stok,Barcode,Kemasan,Isi Kemasan,Barcode Kemasan',
    'Oli Mesin Sport 1L,Oli & Pelumas,botol,65000,24,8997011931117,Dus,12,18997011931114',
    'Baut M8,Suku Cadang,pcs,1000,200,,,,',
    'Busi Iridium,Kelistrikan,pcs,75000,10,4549526611111|4549526622222,Box,10,',
  ].join('\n');

  static List<ImportRow> parse(List<List<String>> table) {
    // Baris judul = baris pertama yang punya kolom "nama".
    final headerIndex = table.indexWhere((row) => row.any((c) => _columns['nama']!.contains(_normalize(c))));
    if (headerIndex == -1) throw DataException('Baris judul tidak ditemukan. Pastikan ada kolom "Nama".');

    final header = table[headerIndex].map(_normalize).toList();
    final index = <String, int>{};
    for (final entry in _columns.entries) {
      final i = header.indexWhere(entry.value.contains);
      if (i != -1) index[entry.key] = i;
    }
    final missing = _required.where((k) => !index.containsKey(k)).toList();
    if (missing.isNotEmpty) {
      const labels = {'nama': 'Nama', 'kategori': 'Kategori', 'satuan': 'Satuan', 'harga': 'Harga Jual'};
      throw DataException('Kolom wajib tidak ditemukan: ${missing.map((k) => labels[k]).join(', ')}');
    }

    String cell(List<String> row, String key) {
      final i = index[key];
      return (i == null || i >= row.length) ? '' : row[i].trim();
    }

    final existingNames = {for (final p in _db.products.rows) p.name.toLowerCase()};
    final namesInFile = <String>{};
    final barcodesInFile = <String>{};
    final rows = <ImportRow>[];

    for (var r = headerIndex + 1; r < table.length; r++) {
      final raw = table[r];
      if (raw.every((c) => c.trim().isEmpty)) continue;

      final barcodes = _splitBarcodes(cell(raw, 'barcode'));
      final packBarcodes = _splitBarcodes(cell(raw, 'barcodekemasan'));
      final row = ImportRow(
        line: r + 1,
        name: cell(raw, 'nama'),
        categoryName: cell(raw, 'kategori'),
        unit: cell(raw, 'satuan'),
        sellPrice: _parseInt(cell(raw, 'harga')) ?? 0,
        stock: _parseInt(cell(raw, 'stok')) ?? 0,
        barcodes: barcodes,
        packName: cell(raw, 'kemasan'),
        packFactor: _parseInt(cell(raw, 'isi')) ?? 0,
        packBarcodes: packBarcodes,
      );

      String? error;
      if (row.name.isEmpty) {
        error = 'Nama kosong';
      } else if (row.categoryName.isEmpty) {
        error = 'Kategori kosong';
      } else if (row.unit.isEmpty) {
        error = 'Satuan kosong';
      } else if (row.sellPrice <= 0) {
        error = 'Harga jual tidak valid';
      } else if ((_parseInt(cell(raw, 'stok')) ?? 0) < 0) {
        error = 'Stok tidak boleh minus';
      } else if (row.hasPack && row.packFactor < 2) {
        error = 'Isi kemasan "${row.packName}" minimal 2';
      } else if (!row.hasPack && packBarcodes.isNotEmpty) {
        error = 'Ada barcode kemasan tapi nama kemasan kosong';
      } else {
        for (final code in [...barcodes, ...packBarcodes]) {
          if (code.toUpperCase().contains('E+')) {
            error = 'Barcode $code rusak (format angka Excel) — ubah kolom barcode ke format Teks';
          } else if (!barcodesInFile.add(code)) {
            error = 'Barcode $code dobel di file';
          } else {
            final owner = ProductService.findByBarcode(code);
            if (owner != null) error = 'Barcode $code sudah dipakai "${owner.name}"';
          }
          if (error != null) break;
        }
      }

      if (error != null) {
        row
          ..status = ImportRowStatus.error
          ..message = error;
      } else if (existingNames.contains(row.name.toLowerCase())) {
        row
          ..status = ImportRowStatus.skipped
          ..message = 'Sudah ada di Gudang';
      } else if (!namesInFile.add(row.name.toLowerCase())) {
        row
          ..status = ImportRowStatus.skipped
          ..message = 'Nama dobel di file';
      }
      rows.add(row);
    }
    if (rows.isEmpty) throw DataException('Tidak ada data barang di bawah baris judul');
    return rows;
  }

  static ImportResult commit(List<ImportRow> rows) {
    final ready = rows.where((r) => r.status == ImportRowStatus.ready).toList();
    var created = 0;
    var newCategories = 0;
    for (final row in ready) {
      var category = _db.categories.rows.where((c) => c.name.toLowerCase() == row.categoryName.toLowerCase()).firstOrNull;
      if (category == null) {
        category = CategoryModel(id: _db.newId('c'), name: row.categoryName);
        _db.categories.insert(category);
        newCategories++;
      }
      try {
        ProductService.insertNow(
          barcodes: row.barcodes,
          packs: [
            if (row.hasPack) ProductPack(name: row.packName, factor: row.packFactor, barcodes: row.packBarcodes),
          ],
          name: row.name,
          categoryId: category.id,
          unit: row.unit,
          buyPrice: 0,
          sellPrice: row.sellPrice,
          stock: row.stock,
          stockNote: 'Stok awal (import data)',
        );
        created++;
      } catch (e) {
        row
          ..status = ImportRowStatus.error
          ..message = e.toString();
      }
    }
    final skipped = rows.length - created;
    AppLog.i(tag, 'commit: $created dibuat, $newCategories kategori baru, $skipped dilewati');
    ActivityLogService.log(
      action: ActivityAction.created,
      entity: ActivityEntity.product,
      subject: 'Import data barang',
      details: [
        ActivityDetail('Barang Baru', '$created'),
        ActivityDetail('Kategori Baru', '$newCategories'),
        ActivityDetail('Dilewati / Error', '$skipped'),
      ],
      description: 'Import data barang: $created barang baru, $newCategories kategori baru, $skipped dilewati',
    );
    return ImportResult(created: created, newCategories: newCategories, skipped: skipped);
  }

  static List<String> _splitBarcodes(String value) =>
      {for (final part in value.split(RegExp(r'[|;\s]+'))) if (part.trim().isNotEmpty) part.trim()}.toList();

  // "Rp 55.000" / "55000" / "55,000" -> 55000.
  static int? _parseInt(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9-]'), '');
    return cleaned.isEmpty ? null : int.tryParse(cleaned);
  }
}
