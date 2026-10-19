// ─── ProductModel ───────────────────────────────────────────────────────────
//
// Satu barang di inventori. `stock` SELALU dihitung dalam satuan dasar
// (`unit`, mis. bungkus/botol) dan berubah lewat penjualan, penyesuaian
// stok, atau stok masuk — tiap perubahan tercatat di kartu stok
// (StockMovementModel). `categoryName` didenormalisasi supaya list tidak
// perlu lookup ke kategori.
//
// Barcode:
// - `barcodes`: barcode satuan dasar — boleh lebih dari satu (mis. kemasan
//   lama & baru, beda distributor). Kosong kalau barangnya tidak punya
//   barcode (mis. baut eceran).
// - `packs`: satuan kemasan (mis. Dus isi 12) dengan barcode sendiri. Scan
//   barcode kemasan = jumlah otomatis dikali isinya.
// Satu barcode hanya boleh dimiliki satu barang (dicek di ProductService).
// `sku` = kode internal unik yang dibuat otomatis (tidak ditampilkan, tapi
// tetap bisa dipakai cari/scan).

class ProductPack {
  final String name;
  // Isi kemasan dalam satuan dasar, mis. 12 (botol per dus).
  final int factor;
  final List<String> barcodes;

  const ProductPack({required this.name, required this.factor, this.barcodes = const []});

  String label(String baseUnit) => '$name ($factor $baseUnit)';

  ProductPack copyWith({String? name, int? factor, List<String>? barcodes}) {
    return ProductPack(name: name ?? this.name, factor: factor ?? this.factor, barcodes: barcodes ?? this.barcodes);
  }
}

// Satuan yang cocok dengan barcode hasil scan: satuan dasar (pack == null,
// faktor 1) atau salah satu kemasan.
class ProductUnitMatch {
  final ProductModel product;
  final ProductPack? pack;

  const ProductUnitMatch(this.product, this.pack);

  int get factor => pack?.factor ?? 1;
  String get unitName => pack?.name ?? product.unit;
}

class ProductModel {
  // Batas "stok menipis" — tidak diinput user, sama untuk semua barang.
  static const defaultMinStock = 5;

  final String id;
  final String sku;
  final List<String> barcodes;
  final List<ProductPack> packs;
  final String name;
  final String categoryId;
  final String categoryName;
  final String unit;
  final int buyPrice;
  final int sellPrice;
  final int stock;
  final int minStock;

  const ProductModel({
    required this.id,
    required this.sku,
    this.barcodes = const [],
    this.packs = const [],
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.minStock,
  });

  // Harga beli opsional — 0 berarti belum diisi.
  bool get hasBuyPrice => buyPrice > 0;

  // Barcode utama satuan dasar ('' kalau tidak ada).
  String get barcode => barcodes.isEmpty ? '' : barcodes.first;
  bool get hasBarcode => barcodes.isNotEmpty;

  // Semua barcode milik barang ini (satuan dasar + kemasan).
  Iterable<String> get allBarcodes sync* {
    yield* barcodes;
    for (final pack in packs) {
      yield* pack.barcodes;
    }
  }

  bool get hasAnyBarcode => allBarcodes.isNotEmpty;

  // Satuan yang punya barcode `code`, atau null kalau bukan milik barang ini.
  ProductUnitMatch? unitForBarcode(String code) {
    if (barcodes.contains(code)) return ProductUnitMatch(this, null);
    for (final pack in packs) {
      if (pack.barcodes.contains(code)) return ProductUnitMatch(this, pack);
    }
    return null;
  }

  // Kemasan dengan isi terbesar (dipakai rincian stok "13 Dus + 4 bungkus").
  ProductPack? get largestPack {
    if (packs.isEmpty) return null;
    return packs.reduce((a, b) => a.factor >= b.factor ? a : b);
  }

  // "134 bungkus" — jumlah dalam satuan dasar.
  String formatQty(int qty) => '$qty $unit';

  // Rincian per kemasan terbesar, mis. "13 Dus + 4 bungkus". '' kalau tidak
  // ada kemasan atau jumlahnya kurang dari satu kemasan.
  String packBreakdown(int qty) {
    final pack = largestPack;
    if (pack == null || qty.abs() < pack.factor) return '';
    final whole = qty ~/ pack.factor;
    final rest = qty % pack.factor;
    return rest == 0 ? '$whole ${pack.name}' : '$whole ${pack.name} + $rest $unit';
  }

  // Dipakai pencarian di Gudang & Kasir: nama, kode internal, semua barcode.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || sku.toLowerCase().contains(q) || allBarcodes.any((b) => b.contains(q));
  }

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock <= minStock;

  ProductModel copyWith({
    String? sku,
    List<String>? barcodes,
    List<ProductPack>? packs,
    String? name,
    String? categoryId,
    String? categoryName,
    String? unit,
    int? buyPrice,
    int? sellPrice,
    int? stock,
    int? minStock,
  }) {
    return ProductModel(
      id: id,
      sku: sku ?? this.sku,
      barcodes: barcodes ?? this.barcodes,
      packs: packs ?? this.packs,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
    );
  }
}
