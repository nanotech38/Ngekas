import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/screen/activity_log_screen.dart';
import 'package:ngekas/screen/report/report_screen.dart';
import 'package:ngekas/screen/report/report_type_picker.dart';
import 'package:ngekas/screen/report/stock_report_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';

// ─── LaporanTab ─────────────────────────────────────────────────────────────
//
// Tab "Laporan" di bottom nav HomeScreen — pintasan ke Laporan Penjualan,
// Laporan Stok, dan Riwayat Aktivitas.

class LaporanTab extends StatelessWidget {
  const LaporanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Laporan')),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mau lihat laporan yang mana?', style: AppTextStyle.bodyMd),
            const SizedBox(height: 16),
            ReportTypeOption(
              icon: Icons.shopping_bag_outlined,
              color: AppColors.income,
              background: AppColors.incomeBackground,
              label: 'Laporan Penjualan',
              subtitle: 'Barang keluar dari kasir & catatan penjualan',
              onTap: () => NavigationService.get().push(const ReportScreen()),
            ),
            const SizedBox(height: 10),
            ReportTypeOption(
              icon: Icons.inventory_outlined,
              color: AppColors.primary,
              background: AppColors.primaryContainer,
              label: 'Laporan Stok',
              subtitle: 'Stok habis, menipis & barang tidak laku',
              onTap: () => NavigationService.get().push(const StockReportScreen()),
            ),
            const SizedBox(height: 10),
            ReportTypeOption(
              icon: Icons.history_rounded,
              color: AppColors.secondary,
              background: AppColors.secondaryContainer,
              label: 'Riwayat Aktivitas',
              subtitle: 'Siapa mengubah apa & kapan',
              onTap: () => NavigationService.get().push(const ActivityLogScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
