import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/transaction_service.dart';

enum TransactionStatus {
  initial,
  loading,
  loaded,
  streamError,
  addSuccess,
  addError,
  updateSuccess,
  updateError,
}

class TransactionState {
  final TransactionStatus status;
  final List<TransactionModel> all;
  final bool isSubmitting;
  final String errorMessage;

  TransactionState({
    required this.status,
    required this.all,
    required this.isSubmitting,
    required this.errorMessage,
  });

  TransactionState.initial()
    : this(status: TransactionStatus.initial, all: const [], isSubmitting: false, errorMessage: '');

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionModel>? all,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      all: all ?? this.all,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── TransactionCubit ───────────────────────────────────────────────────────
//
// Dipakai form satu transaksi (ReportEntryFormSheet lewat AddTransactionSheet,
// mis. Stok Masuk dari layar Barang), satu instance per tipe. Laporan
// Penjualan sendiri pakai SalesReportCubit.

class TransactionCubit extends Cubit<TransactionState> {
  static const tag = 'TransactionCubit';

  final TransactionType type;
  StreamSubscription<List<TransactionModel>>? _subscription;

  TransactionCubit({required this.type}) : super(TransactionState.initial());

  void watch() {
    AppLog.i(tag, 'watch: start');
    emit(state.copyWith(status: TransactionStatus.loading));
    _subscription?.cancel();
    _subscription = TransactionService.watch().listen(
      (all) {
        final ofType = all.where((t) => t.type == type).toList();
        emit(state.copyWith(status: TransactionStatus.loaded, all: ofType));
      },
      onError: (Object e) {
        AppLog.e(tag, 'watch: error', error: e);
        emit(state.copyWith(status: TransactionStatus.streamError, errorMessage: e.toString()));
      },
    );
  }

  Future<void> addTransaction({
    required String productId,
    required int quantity,
    required int unitPrice,
    required DateTime date,
    required String note,
  }) async {
    AppLog.i(tag, 'addTransaction: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      final created = await TransactionService.add(
        type: type,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        date: date,
        note: note,
      );
      emit(state.copyWith(isSubmitting: false, status: TransactionStatus.addSuccess));
      await _logActivity(ActivityAction.created, created);
    } catch (e, st) {
      AppLog.e(tag, 'addTransaction: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: TransactionStatus.addError, errorMessage: e.toString()));
    }
  }

  Future<void> updateTransaction({
    required String id,
    required String productId,
    required int quantity,
    required int unitPrice,
    required DateTime date,
    required String note,
  }) async {
    AppLog.i(tag, 'updateTransaction: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      final updated = await TransactionService.update(
        id: id,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        date: date,
        note: note,
      );
      emit(state.copyWith(isSubmitting: false, status: TransactionStatus.updateSuccess));
      await _logActivity(ActivityAction.updated, updated);
    } catch (e, st) {
      AppLog.e(tag, 'updateTransaction: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: TransactionStatus.updateError, errorMessage: e.toString()));
    }
  }

  Future<void> _logActivity(ActivityAction action, TransactionModel t) {
    return ActivityLogService.log(
      action: action,
      entity: ActivityEntity.transaction,
      subject: t.itemName,
      details: [
        ActivityDetail('Jenis', t.type.label),
        ActivityDetail('Jumlah', '${t.quantity}'),
        ActivityDetail('Harga Satuan', AppCurrency.format(t.unitPrice)),
        ActivityDetail('Total', AppCurrency.format(t.amount)),
        if (t.note.isNotEmpty) ActivityDetail('Catatan', t.note),
      ],
      description: '${t.type.label}: ${t.itemName} x${t.quantity} (${AppCurrency.format(t.amount)})',
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
