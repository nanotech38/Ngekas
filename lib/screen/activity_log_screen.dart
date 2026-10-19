import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/const/app_theme_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/sales_report.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/template/base_template.dart';
import 'package:ngekas/widget/app_bottom_sheet.dart';
import 'package:ngekas/widget/app_button.dart';

// ─── ActivityLogScreen ──────────────────────────────────────────────────────
//
// "Riwayat Aktivitas" — aksi tambah/ubah/hapus transaksi, barang, kategori &
// pengguna. Filternya mengikuti Laporan Penjualan:
// - periode Harian / Bulanan / Pilih Tanggal (+ panah ‹ ›),
// - cari di keterangan / nama pengguna,
// - sheet filter (ikon di AppBar): jenis data, aksi, pengguna; filter aktif
//   tampil sebagai chip yang bisa dihapus.
// Admin melihat semua aktivitas; kasir hanya aktivitasnya sendiri.
// Daftar dikelompokkan per tanggal; tiap entri: ikon jenis data berwarna
// sesuai aksi (hijau tambah, oranye ubah, merah hapus), judul singkat
// "Tambah Barang", keterangan, lalu siapa & jam berapa.
// Murni tampilan, data langsung lewat StreamBuilder.

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  ReportRange _range = ReportRange.daily(DateTime.now());
  String _query = '';
  ActivityEntity? _entity;
  ActivityAction? _action;
  String? _actorName;

  bool get _hasExtraFilter => _entity != null || _action != null || _actorName != null;

  bool get _canGoNext {
    final now = DateTime.now();
    return _range.end.isBefore(DateTime(now.year, now.month, now.day));
  }

  // Kasir hanya melihat aktivitasnya sendiri; admin melihat semua.
  List<ActivityLogModel> _visible(List<ActivityLogModel> all) {
    final user = context.read<AuthCubit>().state.user;
    if (user == null || user.isAdmin) return all;
    return all.where((l) => l.actorName == user.name).toList();
  }

  List<ActivityLogModel> _apply(List<ActivityLogModel> all) {
    final q = _query.trim().toLowerCase();
    // Id log berurutan (mis. l-1005): angka lebih besar = dicatat belakangan.
    // Dipakai sebagai penentu kalau jamnya sama persis.
    int seq(ActivityLogModel l) => int.tryParse(l.id.split('-').last) ?? 0;
    return all.where((l) {
      if (!_range.contains(l.timestamp)) return false;
      if (_entity != null && l.entity != _entity) return false;
      if (_action != null && l.action != _action) return false;
      if (_actorName != null && l.actorName != _actorName) return false;
      if (q.isNotEmpty && !l.searchText.contains(q)) return false;
      return true;
    }).toList()
      // Terbaru dulu (berlaku untuk Harian, Bulanan, maupun Pilih Tanggal).
      ..sort((a, b) {
        final byTime = b.timestamp.compareTo(a.timestamp);
        return byTime != 0 ? byTime : seq(b).compareTo(seq(a));
      });
  }

  // ─── Periode ──────────────────────────────────────────────────────────────

  void _setPeriod(ReportPeriod period) {
    final now = DateTime.now();
    setState(() {
      _range = switch (period) {
        ReportPeriod.daily => ReportRange.daily(now),
        ReportPeriod.monthly => ReportRange.monthly(now),
        ReportPeriod.custom => _range,
      };
    });
  }

  void _shift(int step) {
    final r = _range;
    setState(() {
      _range = switch (r.period) {
        ReportPeriod.daily => ReportRange.daily(DateTime(r.start.year, r.start.month, r.start.day + step)),
        ReportPeriod.monthly => ReportRange.monthly(DateTime(r.start.year, r.start.month + step, 1)),
        ReportPeriod.custom => r,
      };
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Rentang awal tidak boleh melewati hari ini (date picker kena assertion).
    final end = _range.end.isAfter(today) ? today : _range.end;
    final start = _range.start.isAfter(end) ? end : _range.start;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: 'Pilih rentang tanggal',
      saveText: 'Terapkan',
    );
    if (picked != null && mounted) setState(() => _range = ReportRange.custom(picked.start, picked.end));
  }

  // ─── Sheet filter ─────────────────────────────────────────────────────────

  void _openFilterSheet(List<ActivityLogModel> all) {
    final isAdmin = context.read<AuthCubit>().state.user?.isAdmin ?? false;
    // Kasir cuma melihat aktivitasnya sendiri, jadi pilihan "Dilakukan Oleh"
    // tidak ditampilkan.
    final actors = isAdmin ? ({for (final l in all) l.actorName}.toList()..sort()) : <String>[];
    AppBottomSheet.show(
      context,
      builder: (_) => _ActivityFilterSheet(
        entity: _entity,
        action: _action,
        actorName: _actorName,
        actorNames: actors,
        onApply: (entity, action, actorName) => setState(() {
          _entity = entity;
          _action = action;
          _actorName = actorName;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityLogModel>>(
      stream: ActivityLogService.watch(),
      builder: (context, snapshot) {
        final all = _visible(snapshot.data ?? const <ActivityLogModel>[]);
        final logs = _apply(all);

        return BaseTemplate(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Riwayat Aktivitas'),
            actions: [
              IconButton(
                tooltip: 'Filter',
                icon: Badge(
                  isLabelVisible: _hasExtraFilter,
                  smallSize: 8,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.filter_list_rounded),
                ),
                onPressed: () => _openFilterSheet(all),
              ),
            ],
          ),
          child: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildSearchField(),
                    if (_hasExtraFilter) ...[const SizedBox(height: 10), _buildActiveFilters()],
                    const SizedBox(height: 12),
                    if (logs.isEmpty) _buildEmpty() else ..._buildList(logs),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    final isCustom = _range.period == ReportPeriod.custom;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final (index, period) in ReportPeriod.values.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodChip(
                    label: period.label,
                    selected: _range.period == period,
                    onTap: period == ReportPeriod.custom ? _pickCustomRange : () => _setPeriod(period),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isCustom)
                IconButton(
                  tooltip: 'Sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _shift(-1),
                ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isCustom ? _pickCustomRange : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _range.label,
                            style: AppTextStyle.titleSm,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.textMuted),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (!isCustom)
                IconButton(
                  tooltip: 'Berikutnya',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _canGoNext ? () => _shift(1) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.labelMd.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => _query = value),
      style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Cari keterangan atau nama pengguna...',
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: AppFontSize.sm),
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled, size: 20),
        isDense: true,
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_entity != null)
          InputChip(
            label: Text('Jenis: ${_entityLabel(_entity!)}', style: AppTextStyle.labelMd),
            onDeleted: () => setState(() => _entity = null),
          ),
        if (_action != null)
          InputChip(
            label: Text('Aksi: ${_visualFor(_action!).verb}', style: AppTextStyle.labelMd),
            onDeleted: () => setState(() => _action = null),
          ),
        if (_actorName != null)
          InputChip(
            label: Text('Oleh: $_actorName', style: AppTextStyle.labelMd),
            onDeleted: () => setState(() => _actorName = null),
          ),
      ],
    );
  }

  // ─── Daftar per tanggal ───────────────────────────────────────────────────

  List<Widget> _buildList(List<ActivityLogModel> logs) {
    final byDay = <DateTime, List<ActivityLogModel>>{};
    for (final log in logs) {
      final day = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      byDay.putIfAbsent(day, () => []).add(log);
    }

    return [
      for (final entry in byDay.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(AppDate.weekdayDate(entry.key), style: AppTextStyle.titleSm)),
              Text(
                '${entry.value.length} aktivitas',
                style: AppTextStyle.labelMd.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
        for (final log in entry.value) Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildTile(log)),
        const SizedBox(height: 8),
      ],
    ];
  }

  // Kartu: aksi + jenis data (badge berwarna) & jam, nama yang dikenai aksi
  // (besar), maks. 2 baris rincian (perubahan tampil lama → baru), lalu
  // pelaku + perannya. Ketuk = sheet detail lengkap.
  Widget _buildTile(ActivityLogModel log) {
    final visual = _visualFor(log.action);
    final preview = log.details.take(2).toList();
    final more = log.details.length - preview.length;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(log),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(10)),
                child: Icon(_entityIcon(log.entity), color: visual.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ActionBadge(log: log),
                        const Spacer(),
                        Text(
                          AppDate.time(log.timestamp),
                          style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.subject.isNotEmpty ? log.subject : log.description,
                      style: AppTextStyle.titleSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (final detail in preview) _DetailLine(detail: detail, compact: true),
                      if (more > 0)
                        Text(
                          '+$more rincian lainnya',
                          style: AppTextStyle.labelSm.copyWith(color: AppColors.primary),
                        ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _ActorAvatar(name: log.actorName, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            log.actorRole.isNotEmpty ? '${log.actorName} · ${log.actorRole}' : log.actorName,
                            style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textDisabled),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(ActivityLogModel log) {
    AppBottomSheet.show(context, builder: (_) => _ActivityDetailSheet(log: log));
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: AppColors.textHint),
          SizedBox(height: 8),
          Text('Tidak ada aktivitas pada periode ini.', style: AppTextStyle.bodySm, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Sheet detail ───────────────────────────────────────────────────────────
//
// Detail satu aktivitas: aksi & jenis data, nama yang dikenai aksi, semua
// rincian (perubahan tampil lama dicoret → baru), lalu siapa & kapan.

class _ActivityDetailSheet extends StatelessWidget {
  final ActivityLogModel log;

  const _ActivityDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(log.action);
    final changes = log.details.where((d) => d.isChange).toList();
    final infos = log.details.where((d) => !d.isChange).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(12)),
              child: Icon(_entityIcon(log.entity), color: visual.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ActionBadge(log: log),
                  const SizedBox(height: 4),
                  Text(log.subject.isNotEmpty ? log.subject : '-', style: AppTextStyle.titleLg),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (changes.isNotEmpty) ...[
          _buildSectionTitle('Perubahan'),
          _buildBox([for (final d in changes) _buildChangeRow(d)]),
          const SizedBox(height: 16),
        ],
        if (infos.isNotEmpty) ...[
          _buildSectionTitle('Rincian'),
          _buildBox([for (final d in infos) _buildInfoRow(d.label, d.value)]),
          const SizedBox(height: 16),
        ],
        if (log.details.isEmpty) ...[
          _buildSectionTitle('Keterangan'),
          _buildBox([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(log.description, style: AppTextStyle.bodySm.copyWith(color: AppColors.textPrimary)),
            ),
          ]),
          const SizedBox(height: 16),
        ],
        _buildSectionTitle('Dilakukan Oleh'),
        _buildBox([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _ActorAvatar(name: log.actorName, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.actorName, style: AppTextStyle.labelLg),
                      if (log.actorRole.isNotEmpty)
                        Text(log.actorRole, style: AppTextStyle.labelSm.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: AppColors.divider),
          _buildInfoRow('Tanggal', AppDate.weekdayDate(log.timestamp)),
          _buildInfoRow('Jam', AppDate.time(log.timestamp)),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyle.labelLg.copyWith(color: AppColors.textMuted)),
    );
  }

  Widget _buildBox(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyle.labelMd.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: AppTextStyle.labelLg)),
        ],
      ),
    );
  }

  Widget _buildChangeRow(ActivityDetail d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.label, style: AppTextStyle.labelMd.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  d.oldValue!,
                  style: AppTextStyle.labelMd.copyWith(
                    color: AppColors.error,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                child: Text(d.value, style: AppTextStyle.labelMd.copyWith(color: AppColors.success)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Komponen kecil ─────────────────────────────────────────────────────────

// Badge "Tambah Barang" / "Ubah Kategori" / "Hapus Barang" berwarna sesuai aksi.
class _ActionBadge extends StatelessWidget {
  final ActivityLogModel log;

  const _ActionBadge({required this.log});

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(log.action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: visual.background, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '${visual.verb} ${_entityLabel(log.entity)}',
        style: AppTextStyle.labelSm.copyWith(color: visual.color, fontWeight: AppFontWeight.semiBold),
      ),
    );
  }
}

// Satu baris rincian di kartu: "Label: nilai" atau "Label: lama → baru".
class _DetailLine extends StatelessWidget {
  final ActivityDetail detail;
  final bool compact;

  const _DetailLine({required this.detail, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyle.labelSm.copyWith(color: AppColors.textMuted);
    final strong = AppTextStyle.labelSm.copyWith(color: AppColors.textPrimary, fontWeight: AppFontWeight.semiBold);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${detail.label}: ', style: muted),
            if (detail.isChange) ...[
              TextSpan(
                text: detail.oldValue,
                style: muted.copyWith(decoration: TextDecoration.lineThrough),
              ),
              TextSpan(text: '  →  ', style: muted),
            ],
            TextSpan(text: detail.value, style: strong),
          ],
        ),
        maxLines: compact ? 1 : null,
        overflow: compact ? TextOverflow.ellipsis : null,
      ),
    );
  }
}

class _ActorAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _ActorAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
      child: Text(
        initial,
        style: AppTextStyle.labelSm.copyWith(color: AppColors.secondary, fontSize: size * 0.45),
      ),
    );
  }
}

// ─── Sheet filter ───────────────────────────────────────────────────────────

class _ActivityFilterSheet extends StatefulWidget {
  final ActivityEntity? entity;
  final ActivityAction? action;
  final String? actorName;
  final List<String> actorNames;
  final void Function(ActivityEntity? entity, ActivityAction? action, String? actorName) onApply;

  const _ActivityFilterSheet({
    required this.entity,
    required this.action,
    required this.actorName,
    required this.actorNames,
    required this.onApply,
  });

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  late ActivityEntity? _entity = widget.entity;
  late ActivityAction? _action = widget.action;
  late String? _actorName = widget.actorName;

  void _submit(ActivityEntity? entity, ActivityAction? action, String? actorName) {
    widget.onApply(entity, action, actorName);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter Aktivitas', style: AppTextStyle.titleLg),
        const SizedBox(height: 20),
        const Text('Jenis Data', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip('Semua', _entity == null, () => setState(() => _entity = null)),
            for (final e in ActivityEntity.values)
              _buildChip(_entityLabel(e), _entity == e, () => setState(() => _entity = e)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Aksi', style: AppTextStyle.labelLg),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip('Semua', _action == null, () => setState(() => _action = null)),
            for (final a in ActivityAction.values)
              _buildChip(_visualFor(a).verb, _action == a, () => setState(() => _action = a)),
          ],
        ),
        if (widget.actorNames.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Dilakukan Oleh', style: AppTextStyle.labelLg),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Semua Pengguna', _actorName == null, () => setState(() => _actorName = null)),
              for (final name in widget.actorNames)
                _buildChip(name, _actorName == name, () => setState(() => _actorName = name)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => _submit(null, null, null), child: const Text('Reset Filter')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(label: 'Terapkan', onPressed: () => _submit(_entity, _action, _actorName)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: AppTextStyle.labelMd.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ─── Label & warna (dipakai layar & sheet filter) ───────────────────────────

String _entityLabel(ActivityEntity entity) => switch (entity) {
  ActivityEntity.transaction => 'Transaksi',
  ActivityEntity.product => 'Barang',
  ActivityEntity.category => 'Kategori',
  ActivityEntity.member => 'Pengguna',
};

IconData _entityIcon(ActivityEntity entity) => switch (entity) {
  ActivityEntity.transaction => Icons.receipt_long_outlined,
  ActivityEntity.product => Icons.inventory_2_outlined,
  ActivityEntity.category => Icons.category_outlined,
  ActivityEntity.member => Icons.person_add_alt_outlined,
};

_ActionVisual _visualFor(ActivityAction action) => switch (action) {
  ActivityAction.created => const _ActionVisual(
    verb: 'Tambah',
    color: AppColors.income,
    background: AppColors.incomeBackground,
  ),
  ActivityAction.updated => const _ActionVisual(
    verb: 'Ubah',
    color: AppColors.primary,
    background: AppColors.primaryContainer,
  ),
  ActivityAction.deleted => const _ActionVisual(
    verb: 'Hapus',
    color: AppColors.expense,
    background: AppColors.expenseBackground,
  ),
};

class _ActionVisual {
  final String verb;
  final Color color;
  final Color background;

  const _ActionVisual({required this.verb, required this.color, required this.background});
}
