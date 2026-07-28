import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// Logger Instance
final Logger _logger = Logger(
  // Level.off di mode release -> log tidak ikut tercetak di build production.
  // Level.trace di mode debug -> semua level (trace s/d fatal) tampil saat development.
  level: kReleaseMode ? Level.off : Level.trace,
  printer: PrettyPrinter(
    methodCount: 0, // tidak perlu stack trace untuk log biasa
    errorMethodCount:
        5, // tampilkan beberapa baris stack trace saat error/fatal
    lineLength: 100,
    colors: true,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

class AppLog {
  AppLog._();

  /// Log untuk detail teknis saat development (mis. isi variabel, request/response mentah).
  static void d(String tag, dynamic message) => _logger.d('[$tag] $message');

  /// Log untuk alur normal / hasil sukses dari suatu logic (mis. "initialize: done").
  static void i(String tag, dynamic message) => _logger.i('[$tag] $message');

  /// Log untuk kondisi tidak normal tapi belum menyebabkan proses gagal.
  static void w(String tag, dynamic message) => _logger.w('[$tag] $message');

  /// Log untuk error/exception dari suatu logic. Sertakan [error] & [stackTrace] jika ada.
  static void e(
    String tag,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);

  /// Log untuk error fatal yang menghentikan fitur/aplikasi sepenuhnya.
  static void f(
    String tag,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.f('[$tag] $message', error: error, stackTrace: stackTrace);
}
