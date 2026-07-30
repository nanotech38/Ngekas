import 'package:flutter/material.dart';

class MenuItem {
  final int id;
  final IconData icon;
  final String label;

  const MenuItem({required this.id, required this.icon, required this.label});
}

// id dipakai HomeLogic.handleMenuTap untuk menentukan tujuan navigasi
// (switch berdasarkan id, bukan label, supaya ganti teks label tidak
// memutus routing).
const homeMenus = [
  MenuItem(id: 1, icon: Icons.receipt_long_rounded, label: 'Laporan'),
  MenuItem(id: 2, icon: Icons.category_rounded, label: 'Kelola Kategori'),
  MenuItem(id: 3, icon: Icons.group_rounded, label: 'Staff'),
  MenuItem(id: 4, icon: Icons.settings_rounded, label: 'Pengaturan'),
  MenuItem(id: 5, icon: Icons.history_rounded, label: 'Riwayat Aktivitas'),
];
