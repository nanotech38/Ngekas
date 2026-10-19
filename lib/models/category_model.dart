// ─── CategoryModel ──────────────────────────────────────────────────────────
//
// Kategori barang (mis. Minuman, Sembako) — dipakai untuk mengelompokkan
// ProductModel dan sebagai filter di Laporan & Kasir.

class CategoryModel {
  final String id;
  final String name;

  const CategoryModel({required this.id, required this.name});

  CategoryModel copyWith({String? name}) => CategoryModel(id: id, name: name ?? this.name);
}
