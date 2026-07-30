import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_currency_const.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/models/transaction_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/transaction_service.dart';

class TransactionFilter {
  final DateTimeRange? dateRange;
  final String? categoryId;

  const TransactionFilter({this.dateRange, this.categoryId});

  bool get isActive => dateRange != null || categoryId != null;
}

enum TransactionStatus {
  initial,
  loading,
  loaded,
  streamError,
  addSuccess,
  addError,
  updateSuccess,
  updateError,
  deleteSuccess,
  deleteError,
}

class TransactionState {
  final TransactionStatus status;
  final List<TransactionModel> all;
  final TransactionFilter filter;
  final bool isSubmitting;
  final String errorMessage;

  TransactionState({
    required this.status,
    required this.all,
    required this.filter,
    required this.isSubmitting,
    required this.errorMessage,
  });

  TransactionState.initial()
    : this(
        status: TransactionStatus.initial,
        all: const [],
        filter: const TransactionFilter(),
        isSubmitting: false,
        errorMessage: '',
      );

  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionModel>? all,
    TransactionFilter? filter,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return TransactionState(
      status: status ?? this.status,
      all: all ?? this.all,
      filter: filter ?? this.filter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<TransactionModel> get filtered {
    return all.where((t) {
      if (filter.categoryId != null && t.categoryId != filter.categoryId) {
        return false;
      }
      if (filter.dateRange != null) {
        final day = DateTime(t.date.year, t.date.month, t.date.day);
        final start = filter.dateRange!.start;
        final end = filter.dateRange!.end;
        final startDay = DateTime(start.year, start.month, start.day);
        final endDay = DateTime(end.year, end.month, end.day);
        if (day.isBefore(startDay) || day.isAfter(endDay)) return false;
      }
      return true;
    }).toList();
  }
}

// ─── TransactionCubit ───────────────────────────────────────────────────────
//
// Scoped per ReportScreen, satu instance per tipe (income/expense) karena
// ReportScreen sendiri sudah dipilih tipenya lewat submenu di Home — filter
// tipe dilakukan di sini (client-side) mengikuti data mentah dari
// TransactionService.watch yang belum dipisah per tipe.

class TransactionCubit extends Cubit<TransactionState> {
  static const tag = 'TransactionCubit';

  final String ownerId;
  final CategoryType type;
  StreamSubscription<List<TransactionModel>>? _subscription;

  TransactionCubit({required this.ownerId, required this.type})
    : super(TransactionState.initial());

  void watch() {
    AppLog.i(tag, 'watch: start');
    emit(state.copyWith(status: TransactionStatus.loading));
    _subscription?.cancel();
    _subscription = TransactionService.watch(ownerId).listen(
      (all) {
        final ofType = all.where((t) => t.type == type).toList();
        emit(state.copyWith(status: TransactionStatus.loaded, all: ofType));
      },
      onError: (Object e) {
        AppLog.e(tag, 'watch: error', error: e);
        emit(
          state.copyWith(
            status: TransactionStatus.streamError,
            errorMessage: e.toString(),
          ),
        );
      },
    );
  }

  void applyFilter(TransactionFilter filter) {
    AppLog.i(tag, 'applyFilter');
    emit(state.copyWith(filter: filter));
  }

  void clearFilter() {
    AppLog.i(tag, 'clearFilter');
    emit(state.copyWith(filter: const TransactionFilter()));
  }

  Future<void> addTransaction({
    required String categoryId,
    required String categoryName,
    required String itemName,
    required int quantity,
    required int amount,
    required DateTime date,
    required String note,
  }) async {
    AppLog.i(tag, 'addTransaction: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      await TransactionService.add(
        ownerId: ownerId,
        type: type,
        categoryId: categoryId,
        categoryName: categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
        date: date,
        note: note,
      );
      AppLog.i(tag, 'addTransaction: success');
      emit(
        state.copyWith(isSubmitting: false, status: TransactionStatus.addSuccess),
      );
      await _logActivity(
        ActivityAction.created,
        categoryName: categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
      );
    } catch (e, st) {
      AppLog.e(tag, 'addTransaction: error', error: e, stackTrace: st);
      emit(
        state.copyWith(
          isSubmitting: false,
          status: TransactionStatus.addError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> updateTransaction({
    required String id,
    required String categoryId,
    required String categoryName,
    required String itemName,
    required int quantity,
    required int amount,
    required DateTime date,
    required String note,
  }) async {
    AppLog.i(tag, 'updateTransaction: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      await TransactionService.update(
        ownerId: ownerId,
        id: id,
        categoryId: categoryId,
        categoryName: categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
        date: date,
        note: note,
      );
      AppLog.i(tag, 'updateTransaction: success');
      emit(
        state.copyWith(isSubmitting: false, status: TransactionStatus.updateSuccess),
      );
      await _logActivity(
        ActivityAction.updated,
        categoryName: categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
      );
    } catch (e, st) {
      AppLog.e(tag, 'updateTransaction: error', error: e, stackTrace: st);
      emit(
        state.copyWith(
          isSubmitting: false,
          status: TransactionStatus.updateError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteTransaction({
    required String id,
    required String categoryName,
    required String itemName,
    required int quantity,
    required int amount,
  }) async {
    AppLog.i(tag, 'deleteTransaction: start');
    try {
      await TransactionService.delete(ownerId: ownerId, id: id);
      AppLog.i(tag, 'deleteTransaction: success');
      emit(state.copyWith(status: TransactionStatus.deleteSuccess));
      await _logActivity(
        ActivityAction.deleted,
        categoryName: categoryName,
        itemName: itemName,
        quantity: quantity,
        amount: amount,
      );
    } catch (e, st) {
      AppLog.e(tag, 'deleteTransaction: error', error: e, stackTrace: st);
      emit(
        state.copyWith(
          status: TransactionStatus.deleteError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _logActivity(
    ActivityAction action, {
    required String categoryName,
    required String itemName,
    required int quantity,
    required int amount,
  }) {
    final label = type == CategoryType.income ? 'Pemasukan' : 'Pengeluaran';
    return ActivityLogService.log(
      ownerId: ownerId,
      actorEmail: AuthService.currentUser?.email ?? '-',
      action: action,
      entity: ActivityEntity.transaction,
      description:
          '$label: $categoryName - $itemName x$quantity (${AppCurrency.format(amount)})',
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
