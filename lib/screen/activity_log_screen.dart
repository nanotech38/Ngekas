import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/template/base_template.dart';

// ─── ActivityLogScreen ──────────────────────────────────────────────────────
//
// Menu "Riwayat Aktivitas" — daftar aksi tambah/ubah/hapus laporan & kategori
// yang pernah dilakukan siapa saja di workspace ini. Murni tampilan (tidak
// ada aksi apa pun di sini), jadi ambil data langsung lewat StreamBuilder,
// sama pola dengan HomeTab & CategoryDropdownField.

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = context.read<AuthCubit>().state.user!.ownerId;

    return BaseTemplate(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Aktivitas')),
      child: StreamBuilder<List<ActivityLogModel>>(
        stream: ActivityLogService.watch(ownerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat riwayat aktivitas.',
                  style: AppTextStyle.bodyMd,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final logs = snapshot.data ?? const <ActivityLogModel>[];
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Belum ada aktivitas yang tercatat.',
                  style: AppTextStyle.bodyMd,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildTile(logs[index]),
          );
        },
      ),
    );
  }

  Widget _buildTile(ActivityLogModel log) {
    final visual = _visualFor(log.action);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: visual.background, shape: BoxShape.circle),
            child: Icon(visual.icon, color: visual.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.actorEmail} ${_actionLabel(log.action, log.entity)}',
                  style: AppTextStyle.labelLg,
                ),
                const SizedBox(height: 2),
                Text(log.description, style: AppTextStyle.bodySm),
                const SizedBox(height: 6),
                Text(
                  AppDate.formatDateTime(log.timestamp),
                  style: AppTextStyle.labelSm.copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(ActivityAction action, ActivityEntity entity) {
    final noun = switch (entity) {
      ActivityEntity.transaction => 'laporan',
      ActivityEntity.category => 'kategori',
      ActivityEntity.member => 'anggota',
    };
    switch (action) {
      case ActivityAction.created:
        return 'menambahkan $noun';
      case ActivityAction.updated:
        return 'mengubah $noun';
      case ActivityAction.deleted:
        return 'menghapus $noun';
    }
  }

  _ActionVisual _visualFor(ActivityAction action) {
    switch (action) {
      case ActivityAction.created:
        return const _ActionVisual(
          icon: Icons.add_rounded,
          color: AppColors.income,
          background: AppColors.incomeBackground,
        );
      case ActivityAction.updated:
        return const _ActionVisual(
          icon: Icons.edit_rounded,
          color: AppColors.secondary,
          background: AppColors.secondaryContainer,
        );
      case ActivityAction.deleted:
        return const _ActionVisual(
          icon: Icons.delete_rounded,
          color: AppColors.expense,
          background: AppColors.expenseBackground,
        );
    }
  }
}

class _ActionVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const _ActionVisual({required this.icon, required this.color, required this.background});
}
