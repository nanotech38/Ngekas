import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger(
  level: kReleaseMode ? Level.off : Level.trace,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

class AppLog {
  AppLog._();

  static void d(String tag, dynamic message) => _logger.d('[$tag] $message');

  static void i(String tag, dynamic message) => _logger.i('[$tag] $message');

  static void w(String tag, dynamic message) => _logger.w('[$tag] $message');

  static void e(
    String tag,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);

  static void f(
    String tag,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.f('[$tag] $message', error: error, stackTrace: stackTrace);
}
