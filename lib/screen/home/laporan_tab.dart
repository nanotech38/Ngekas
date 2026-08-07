import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/screen/report/report_screen.dart';
import 'package:ngekas/services/navigation_services.dart';
import 'package:ngekas/template/base_template.dart';

// ─── LaporanTab ─────────────────────────────────────────────────────────────
//
// Tab "Laporan" di bottom nav HomeScreen — pilih dulu mau lihat laporan
// Pemasukan atau Pengeluaran, baru diarahkan ke ReportScreen dengan tipe
// yang sudah tetap. Sama pola pilihannya dengan ReportTypePicker (bottom
// sheet dari FAB), tapi di sini full screen sebagai isi tab.

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
            _buildOption(
              icon: Icons.arrow_downward_rounded,
              color: AppColors.income,
              background: AppColors.incomeBackground,
              label: 'Laporan Pemasukan',
              type: CategoryType.income,
            ),
            const SizedBox(height: 10),
            _buildOption(
              icon: Icons.arrow_upward_rounded,
              color: AppColors.expense,
              background: AppColors.expenseBackground,
              label: 'Laporan Pengeluaran',
              type: CategoryType.expense,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color color,
    required Color background,
    required String label,
    required CategoryType type,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => NavigationService.get().push(ReportScreen(type: type)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTextStyle.titleSm)),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
