import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_log_const.dart';
import 'package:ngekas/models/activity_log_model.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/services/activity_log_service.dart';
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
    : this(status: CategoryStatus.initial, categories: const [], isSubmitting: false, errorMessage: '');

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

class CategoryCubit extends Cubit<CategoryState> {
  static const tag = 'CategoryCubit';

  StreamSubscription<List<CategoryModel>>? _subscription;

  CategoryCubit() : super(CategoryState.initial());

  void watch() {
    AppLog.i(tag, 'watch: start');
    emit(state.copyWith(status: CategoryStatus.loading));
    _subscription?.cancel();
    _subscription = CategoryService.watch().listen(
      (categories) => emit(state.copyWith(status: CategoryStatus.loaded, categories: categories)),
      onError: (Object e) {
        AppLog.e(tag, 'watch: error', error: e);
        emit(state.copyWith(status: CategoryStatus.streamError, errorMessage: e.toString()));
      },
    );
  }

  Future<void> addCategory({required String name}) async {
    AppLog.i(tag, 'addCategory: start');
    emit(state.copyWith(isSubmitting: true));
    try {
      await CategoryService.add(name: name);
      emit(state.copyWith(isSubmitting: false, status: CategoryStatus.addSuccess));
      await _logActivity(ActivityAction.created, name);
    } catch (e, st) {
      AppLog.e(tag, 'addCategory: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: CategoryStatus.addError, errorMessage: e.toString()));
    }
  }

  Future<void> updateCategory({required String id, required String name}) async {
    AppLog.i(tag, 'updateCategory: start');
    emit(state.copyWith(isSubmitting: true));
    final oldName = state.categories.where((c) => c.id == id).firstOrNull?.name;
    try {
      await CategoryService.update(id: id, name: name);
      emit(state.copyWith(isSubmitting: false, status: CategoryStatus.updateSuccess));
      await _logActivity(
        ActivityAction.updated,
        name,
        details: [if (oldName != null && oldName != name) ActivityDetail.change('Nama', oldName, name)],
      );
    } catch (e, st) {
      AppLog.e(tag, 'updateCategory: error', error: e, stackTrace: st);
      emit(state.copyWith(isSubmitting: false, status: CategoryStatus.updateError, errorMessage: e.toString()));
    }
  }

  Future<void> deleteCategory({required String id, required String name}) async {
    AppLog.i(tag, 'deleteCategory: start');
    try {
      await CategoryService.delete(id: id);
      emit(state.copyWith(status: CategoryStatus.deleteSuccess));
      await _logActivity(ActivityAction.deleted, name);
    } catch (e, st) {
      AppLog.e(tag, 'deleteCategory: error', error: e, stackTrace: st);
      emit(state.copyWith(status: CategoryStatus.deleteError, errorMessage: e.toString()));
    }
  }

  Future<void> _logActivity(ActivityAction action, String name, {List<ActivityDetail> details = const []}) {
    return ActivityLogService.log(
      action: action,
      entity: ActivityEntity.category,
      subject: name,
      details: details,
      description: 'Kategori: $name${details.isEmpty ? '' : ' (${details.map((d) => d.summary).join(', ')})'}',
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
