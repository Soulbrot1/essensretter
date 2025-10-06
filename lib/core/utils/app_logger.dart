import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Zentraler App-Logger
///
/// Nur in Debug-Modus aktiv, in Production werden keine Logs ausgegeben.
///
/// Usage:
/// ```dart
/// AppLogger.debug('Debug message');
/// AppLogger.info('Info message');
/// AppLogger.warning('Warning message');
/// AppLogger.error('Error message', error: e, stackTrace: stackTrace);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    filter: _ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug-Level Log (nur für Entwicklung)
  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info-Level Log
  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning-Level Log
  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error-Level Log
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

/// Custom Filter: Nur in Debug-Modus loggen
class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In Production keine Logs
    return kDebugMode;
  }
}
