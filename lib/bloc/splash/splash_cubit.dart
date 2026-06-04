import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/const/app_rc_const.dart';
import 'package:ngekas/services/database_service.dart';

class SplashState {
  final bool inLoading;
  final String rc;
  final String errorMsg;
  final String message;
  final double progress;

  SplashState({
    required this.inLoading,
    required this.rc,
    required this.errorMsg,
    required this.message,
    required this.progress,
  });

  SplashState.init()
    : this(inLoading: false, rc: '', errorMsg: '', message: '', progress: 0.0);

  SplashState.loading({required String message, required double progress})
    : this(
        inLoading: true,
        rc: '',
        errorMsg: '',
        message: message,
        progress: progress,
      );

  SplashState.done({required String rc, required String errorMsg})
    : this(
        inLoading: false,
        rc: rc,
        errorMsg: errorMsg,
        message: rc == rcSuccess ? 'Aplikasi siap!' : errorMsg,
        progress: rc == rcSuccess ? 1.0 : 0.0,
      );
}

class SplashCubit extends Cubit<SplashState> {
  static const tag = 'SplashCubit';

  SplashCubit() : super(SplashState.init());

  Future<void> initialize() async {
    debugPrint('[$tag] initialize: start');
    try {
      await DatabaseService.instance.init((message, progress) {
        emit(SplashState.loading(message: message, progress: progress));
      });
      debugPrint('[$tag] initialize: done');
      emit(SplashState.done(rc: rcSuccess, errorMsg: ''));
    } catch (e) {
      debugPrint('[$tag] initialize: error=$e');
      emit(SplashState.done(rc: rcError, errorMsg: e.toString()));
    }
  }
}
