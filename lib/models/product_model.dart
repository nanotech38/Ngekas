class ProductPack {
  final String name;
  final int factor;
  final List<String> barcodes;

  const ProductPack({required this.name, required this.factor, this.barcodes = const []});

  String label(String baseUnit) => '$name ($factor $baseUnit)';

  ProductPack copyWith({String? name, int? factor, List<String>? barcodes}) {
    return ProductPack(name: name ?? this.name, factor: factor ?? this.factor, barcodes: barcodes ?? this.barcodes);
  }
}

class ProductUnitMatch {
  final ProductModel product;
  final ProductPack? pack;

  const ProductUnitMatch(this.product, this.pack);

  int get factor => pack?.factor ?? 1;
  String get unitName => pack?.name ?? product.unit;
}

class ProductModel {
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
  // selalu dalam satuan dasar (unit), bukan kemasan
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

  bool get hasBuyPrice => buyPrice > 0;

  String get barcode => barcodes.isEmpty ? '' : barcodes.first;
  bool get hasBarcode => barcodes.isNotEmpty;

  Iterable<String> get allBarcodes sync* {
    yield* barcodes;
    for (final pack in packs) {
      yield* pack.barcodes;
    }
  }

  bool get hasAnyBarcode => allBarcodes.isNotEmpty;

  ProductUnitMatch? unitForBarcode(String code) {
    if (barcodes.contains(code)) return ProductUnitMatch(this, null);
    for (final pack in packs) {
      if (pack.barcodes.contains(code)) return ProductUnitMatch(this, pack);
    }
    return null;
  }

  ProductPack? get largestPack {
    if (packs.isEmpty) return null;
    return packs.reduce((a, b) => a.factor >= b.factor ? a : b);
  }

  String formatQty(int qty) => '$qty $unit';

  String packBreakdown(int qty) {
    final pack = largestPack;
    if (pack == null || qty.abs() < pack.factor) return '';
    final whole = qty ~/ pack.factor;
    final rest = qty % pack.factor;
    return rest == 0 ? '$whole ${pack.name}' : '$whole ${pack.name} + $rest $unit';
  }

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
