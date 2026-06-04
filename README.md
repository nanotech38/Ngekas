<div align="center">

# 🧾 Ngekas
### Aplikasi Catatan Penjualan untuk Warung & Usaha Kecil

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?style=flat-square&logo=sqlite&logoColor=white)](https://pub.dev/packages/sqflite)
[![BLoC](https://img.shields.io/badge/State-Cubit%2FBLoC-13B9FD?style=flat-square&logo=bloc&logoColor=white)](https://pub.dev/packages/flutter_bloc)

> Catat pemasukan dan pengeluaran usahamu dengan mudah — tanpa ribet, tanpa internet.

</div>

---

## ✨ Fitur Utama

| Fitur | Keterangan |
|---|---|
| 📥 **Input Penjualan** | Catat pemasukan harian dengan kategori dan keterangan |
| 📤 **Input Pengeluaran** | Catat biaya operasional seperti belanja bahan, listrik, sewa |
| 📊 **Ringkasan Harian** | Lihat total pemasukan & pengeluaran per hari |
| 🗂️ **Kategori Custom** | Tambah kategori sendiri jika pilihan bawaan tidak sesuai |
| 💾 **Offline First** | Semua data tersimpan lokal di perangkat (SQLite) |
| 🔒 **Tanpa Akun** | Tidak perlu daftar atau login |

---

## 📱 Tampilan Aplikasi

> *Screenshot menyusul setelah build selesai*

---

## 🗂️ Struktur Proyek

```
lib/
├── bloc/
│   └── splash/
│       └── splash_cubit.dart     # State & Cubit splash screen
├── const/
│   ├── app_theme_const.dart      # Warna, font size, text style
│   └── app_rc_const.dart         # Response code (SUCCESS / ERROR)
├── model/                        # Data models
├── screen/
│   └── splash_screen.dart        # Splash screen dengan animasi
├── services/
│   ├── database_service.dart     # SQLite — init, CRUD kategori & transaksi
│   └── navigation_services.dart  # Global navigator key & helper navigasi
├── logic/                        # Business logic
└── widget/
    └── app_text_field.dart       # Reusable TextField (text, password, currency, dll)
```

---

## 🗃️ Skema Database

### Tabel `categories`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | Auto increment |
| `name` | TEXT | Nama kategori |
| `type` | TEXT | `income` / `expense` |
| `icon` | TEXT | Nama Material Icon |
| `color` | TEXT | Hex warna (`0xFFxxxxxx`) |
| `is_custom` | INTEGER | `0` = default, `1` = buatan user |
| `created_at` | TEXT | ISO 8601 timestamp |

### Tabel `transactions`
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PK | Auto increment |
| `category_id` | INTEGER FK | Referensi ke `categories.id` |
| `type` | TEXT | `income` / `expense` |
| `amount` | INTEGER | Nominal dalam Rupiah |
| `description` | TEXT | Keterangan opsional |
| `date` | TEXT | Tanggal transaksi |
| `created_at` | TEXT | ISO 8601 timestamp |

### Kategori Default Bawaan

**Pemasukan**
- 🍽️ Makanan · 🥤 Minuman · ➕ Lainnya

**Pengeluaran**
- 🛒 Belanja Bahan · ⚡ Listrik & Air · 🏪 Sewa Tempat · 👥 Gaji Karyawan · ➕ Lainnya

> Kategori default tidak bisa dihapus. Kategori buatan user bisa diedit dan dihapus kapan saja.

---

## 🎨 Design System

Tema warna **Teal + Amber** — profesional dan ramah untuk pengguna warung.

| Token | Hex | Kegunaan |
|---|---|---|
| `AppColors.primary` | `#0F766E` | Tombol, border fokus, icon aktif |
| `AppColors.secondary` | `#F59E0B` | Aksen & highlight |
| `AppColors.income` | `#16A34A` | Nominal pemasukan |
| `AppColors.expense` | `#EF4444` | Nominal pengeluaran |
| `AppColors.background` | `#F8FAFC` | Latar scaffold |
| `AppColors.surface` | `#FFFFFF` | Card & input field |

---

## 🚀 Cara Menjalankan

**Prasyarat:** Flutter SDK 3.x sudah terpasang

```bash
# 1. Clone repo
git clone https://github.com/nanotech38/Ngekas.git
cd Ngekas

# 2. Install dependencies
flutter pub get

# 3. Jalankan di emulator / device
flutter run
```

---

## 📦 Dependencies

| Package | Versi | Kegunaan |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | State management (Cubit) |
| `equatable` | ^2.0.7 | Perbandingan state |
| `sqflite` | ^2.3.3 | Database lokal SQLite |
| `path` | ^1.9.0 | Path database |
| `page_transition` | ^2.2.2 | Animasi perpindahan halaman |

---

## 🛠️ Tech Stack

- **Framework** — Flutter (Dart)
- **State Management** — flutter_bloc (Cubit pattern)
- **Database** — SQLite via sqflite
- **Architecture** — Feature-first, layered (screen / bloc / logic / services / model)

---

<div align="center">

Dibuat dengan ❤️ untuk para pejuang warung Indonesia 🇮🇩

</div>
