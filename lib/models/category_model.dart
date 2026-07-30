// ─── CategoryModel ──────────────────────────────────────────────────────────
//
// Kategori pemasukan/pengeluaran yang dipilih user saat mengisi Laporan.
// Disimpan di Firestore /workspaces/{ownerId}/categories/{id}, berbagi
// workspace yang sama dengan AppUser.ownerId.

enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final CategoryType type;

  const CategoryModel({required this.id, required this.name, required this.type});

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      type: (map['type'] as String?) == 'expense'
          ? CategoryType.expense
          : CategoryType.income,
    );
  }
}
