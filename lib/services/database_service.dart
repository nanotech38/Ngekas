import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  static const _dbVersion = 2;

  Database? _db;
  Database get db => _db!;

  // ─── Init ────────────────────────────────────────────────────────────────────

  Future<void> init(
    void Function(String message, double progress) onProgress,
  ) async {
    onProgress('Mempersiapkan database...', 0.1);
    await Future.delayed(const Duration(milliseconds: 200));

    onProgress('Membuka database...', 0.3);
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ngekas.db');

    bool isFirstRun = false;

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        isFirstRun = true;
        onProgress('Membuat tabel...', 0.5);
        await _createTables(db);
        onProgress('Menambahkan kategori awal...', 0.75);
        await _seedCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // tambah kolom is_custom & seed ulang kategori Lainnya untuk income
          await db.execute(
            'ALTER TABLE categories ADD COLUMN is_custom INTEGER NOT NULL DEFAULT 0',
          );
          final now = DateTime.now().toIso8601String();
          await db.insert('categories', {
            'name': 'Lainnya',
            'type': 'income',
            'icon': 'more_horiz',
            'color': '0xFF94A3B8',
            'is_custom': 0,
            'created_at': now,
          });
        }
      },
    );

    if (!isFirstRun) {
      onProgress('Memuat data...', 0.6);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    onProgress('Database siap!', 0.9);
    await Future.delayed(const Duration(milliseconds: 300));
    onProgress('Aplikasi siap!', 1.0);
  }

  // ─── Schema ──────────────────────────────────────────────────────────────────

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        type       TEXT    NOT NULL,
        icon       TEXT    NOT NULL,
        color      TEXT    NOT NULL,
        is_custom  INTEGER NOT NULL DEFAULT 0,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        type        TEXT    NOT NULL,
        amount      INTEGER NOT NULL,
        description TEXT,
        date        TEXT    NOT NULL,
        created_at  TEXT    NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');
  }

  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    final categories = [
      // ── Pemasukan ──────────────────────────────────────────────────────────
      {
        'name': 'Makanan',
        'type': 'income',
        'icon': 'restaurant',
        'color': '0xFF16A34A',
        'is_custom': 0,
        'created_at': now,
      },
      {
        'name': 'Minuman',
        'type': 'income',
        'icon': 'local_drink',
        'color': '0xFF0EA5E9',
        'is_custom': 0,
        'created_at': now,
      },
      {
        'name': 'Lainnya',
        'type': 'income',
        'icon': 'more_horiz',
        'color': '0xFF94A3B8',
        'is_custom': 0,
        'created_at': now,
      },
      // ── Pengeluaran ────────────────────────────────────────────────────────
      {
        'name': 'Belanja Bahan',
        'type': 'expense',
        'icon': 'shopping_cart',
        'color': '0xFFEF4444',
        'is_custom': 0,
        'created_at': now,
      },
      {
        'name': 'Listrik & Air',
        'type': 'expense',
        'icon': 'bolt',
        'color': '0xFFF59E0B',
        'is_custom': 0,
        'created_at': now,
      },
      {
        'name': 'Sewa Tempat',
        'type': 'expense',
        'icon': 'store',
        'color': '0xFFEC4899',
        'is_custom': 0,
        'created_at': now,
      },
      {
        'name': 'Gaji Karyawan',
        'type': 'expense',
        'icon': 'people',
        'color': '0xFF6366F1',
        'is_custom': 0,
        'created_at': now,
      },
      {
        'name': 'Lainnya',
        'type': 'expense',
        'icon': 'more_horiz',
        'color': '0xFF94A3B8',
        'is_custom': 0,
        'created_at': now,
      },
    ];

    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  // ─── Categories CRUD ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    if (type != null) {
      return db.query(
        'categories',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'is_custom ASC, name ASC',
      );
    }
    return db.query('categories', orderBy: 'is_custom ASC, name ASC');
  }

  Future<int> addCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) {
    return db.insert('categories', {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_custom': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateCategory({
    required int id,
    required String name,
    required String icon,
    required String color,
  }) {
    return db.update(
      'categories',
      {'name': name, 'icon': icon, 'color': color},
      // hanya kategori buatan user yang boleh diedit
      where: 'id = ? AND is_custom = 1',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) {
    return db.delete(
      'categories',
      // hanya kategori buatan user yang boleh dihapus
      where: 'id = ? AND is_custom = 1',
      whereArgs: [id],
    );
  }

  // ─── Misc ────────────────────────────────────────────────────────────────────

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
