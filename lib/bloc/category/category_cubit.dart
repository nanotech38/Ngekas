import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
import 'package:ngekas/services/auth_service.dart';
import 'package:ngekas/services/category_service.dart';

enum CategoryStatus {
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

class CategoryState {
  final CategoryStatus status;
  final List<CategoryModel> categories;
  final bool isSubmitting;
  final String errorMessage;

  CategoryState({
    required this.status,
    required this.categories,
    required this.isSubmitting,
    required this.errorMessage,
  });

  CategoryState.initial()
    : this(
        status: CategoryStatus.initial,
        categories: const [],
        isSubmitting: false,
        errorMessage: '',
      );

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryModel>? categories,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── CategoryCubit ──────────────────────────────────────────────────────────
//
// Scoped per CategoryScreen (bukan app-wide seperti AuthCubit), tapi tetap
// dipakai bareng oleh layar list & bottom sheet form (lewat BlocProvider.value)
// selagi sheet terbuka di atas list. Supaya listener keduanya tidak
// saling bereaksi ke status yang bukan urusannya, tiap aksi (add/update/
// delete) punya status sukses/gagal sendiri-sendiri — bukan satu status
// generik success/error (lihat catatan yang sama di AuthCubit).

class CategoryCubit extends Cubit<CategoryState> {
  static const tag = 'CategoryCubit';

  final String ownerId;
  StreamSubscription<List<CategoryModel>>? _subscription;

  CategoryCubit({required this.ownerId}) : super(CategoryState.initial());

  void watch() {
    AppLog.i(tag, 'watch: start');
    emit(state.copyWith(status: CategoryStatus.loading));
    _subscription?.cancel();
    _subscription = CategoryService.watch(ownerId).listen(
      (categories) {
        emit(
          state.copyWith(status: CategoryStatus.loaded, categories: categories),
        );
      },
      onError: (Object e) {
        // Kalau ini muncul pas/abis logout, listener ini belum sempat
        // di-cancel (CategoryScreen tetap hidup di IndexedStack shell Home
        // biar state tab lain tidak hilang) padahal Auth sudah sign-out
        // duluan — Firestore langsung tolak listener yang masih terbuka
        // (permission-denied) sebelum widget-nya sempat unmount. Tidak ada
        // yang perlu dikasih tahu lagi ke user yang sudah keluar, jadi cukup
        // di-log, jangan emit streamError (yang bakal munculin dialog
        // "Gagal" nyasar pas proses logout).
        if (AuthService.currentUser == null) {
          AppLog.i(tag, 'watch: stream error diabaikan (user sudah logout)');
          return;
        }
        AppLog.e(tag, 'watch: error', error: e);
        emit(
          state.copyWith(
            status: CategoryStatus.streamError,
            errorMessage: e.toString(),
          ),
        );
      },
    );
  }

  Future<void> addCategory({
    required String name,
    required CategoryType type,
  }) async {
    AppLog.i(tag, 'addCategory: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      await CategoryService.add(ownerId: ownerId, name: name, type: type);
      AppLog.i(tag, 'addCategory: success');
      emit(
        state.copyWith(isSubmitting: false, status: CategoryStatus.addSuccess),
      );
      await _logActivity(ActivityAction.created, name: name, type: type);
    } catch (e, st) {
      AppLog.e(tag, 'addCategory: error', error: e, stackTrace: st);
      emit(
        state.copyWith(
          isSubmitting: false,
          status: CategoryStatus.addError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required CategoryType type,
  }) async {
    AppLog.i(tag, 'updateCategory: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      await CategoryService.update(ownerId: ownerId, id: id, name: name);
      AppLog.i(tag, 'updateCategory: success');
      emit(
        state.copyWith(
          isSubmitting: false,
          status: CategoryStatus.updateSuccess,
        ),
      );
      await _logActivity(ActivityAction.updated, name: name, type: type);
    } catch (e, st) {
      AppLog.e(tag, 'updateCategory: error', error: e, stackTrace: st);
      emit(
        state.copyWith(
          isSubmitting: false,
          status: CategoryStatus.updateError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteCategory({
    required String id,
    required String name,
    required CategoryType type,
  }) async {
    AppLog.i(tag, 'deleteCategory: start');
    try {
      await CategoryService.delete(ownerId: ownerId, id: id);
      AppLog.i(tag, 'deleteCategory: success');
      emit(state.copyWith(status: CategoryStatus.deleteSuccess));
      await _logActivity(ActivityAction.deleted, name: name, type: type);
    } catch (e, st) {
      AppLog.e(tag, 'deleteCategory: error', error: e, stackTrace: st);
      emit(
        state.copyWith(
          status: CategoryStatus.deleteError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _logActivity(
    ActivityAction action, {
    required String name,
    required CategoryType type,
  }) {
    final label = type == CategoryType.income ? 'Pemasukan' : 'Pengeluaran';
    return ActivityLogService.log(
      ownerId: ownerId,
      actorEmail: AuthService.currentUser?.email ?? '-',
      action: action,
      entity: ActivityEntity.category,
      description: 'Kategori $label: $name',
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
