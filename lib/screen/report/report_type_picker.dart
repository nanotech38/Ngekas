import 'package:flutter/material.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/logic/report_logic.dart';
import 'package:ngekas/models/category_model.dart';

// ─── ReportTypePicker ───────────────────────────────────────────────────────
//
// Isi bottom sheet submenu saat menu "Laporan" di Home ditekan — user pilih
// mau lihat laporan Pemasukan atau Pengeluaran dulu, baru diarahkan ke
// ReportScreen dengan tipe yang sudah tetap (jadi form tambah entri nanti
// tidak perlu tahap pilih tipe lagi).

class ReportTypePicker extends StatelessWidget {
  const ReportTypePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Laporan', style: AppTextStyle.titleLg),
        const SizedBox(height: 4),
        const Text('Mau lihat laporan yang mana?', style: AppTextStyle.bodySm),
        const SizedBox(height: 20),
        _buildOption(
          context,
          icon: Icons.arrow_downward_rounded,
          color: AppColors.income,
          background: AppColors.incomeBackground,
          label: 'Laporan Pemasukan',
          type: CategoryType.income,
        ),
        const SizedBox(height: 10),
        _buildOption(
          context,
          icon: Icons.arrow_upward_rounded,
          color: AppColors.expense,
          background: AppColors.expenseBackground,
          label: 'Laporan Pengeluaran',
          type: CategoryType.expense,
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
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
        onTap: () => ReportLogic.openReport(context, type),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
