import 'dart:developer' as developer;

/// Severity levels for logging.
enum LogLevel implements Comparable<LogLevel> {
  debug(100, 'DEBUG', '\x1B[36m'),   // Cyan
  info(200, 'INFO', '\x1B[34m'),     // Blue
  warning(300, 'WARN', '\x1B[33m'),   // Yellow
  error(400, 'ERROR', '\x1B[31m'),   // Red
  fatal(500, 'FATAL', '\x1B[35m');   // Magenta

  final int value;
  final String label;
  final String ansiColor;

  const LogLevel(this.value, this.label, this.ansiColor);

  @override
  int compareTo(LogLevel other) => value.compareTo(other.value);
}

/// A structured log record containing details of the log event.
class LogRecord {
  final DateTime time;
  final LogLevel level;
  final String message;
  final String loggerName;
  final Object? error;
  final StackTrace? stackTrace;

  LogRecord({
    required this.time,
    required this.level,
    required this.message,
    required this.loggerName,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('${time.toIso8601String()} ')
      ..write('[${level.label}] ')
      ..write('$loggerName: ')
      ..write(message);
    if (error != null) {
      buffer.write('\nError: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Signature for custom log printer callbacks.
typedef LogCallback = void Function(LogRecord record);

/// A production-grade, zero-dependency custom logger for Dart and Flutter.
class DevLogger {
  final String name;

  /// The minimum severity level to log. Log events below this level will be ignored.
  static LogLevel minLevel = LogLevel.debug;

  /// Whether ANSI color escapes should be enabled for console output.
  static bool enableColors = true;

  /// Whether logging output to the console is fully silenced.
  static bool quiet = const bool.fromEnvironment('QUIET', defaultValue: false);

  /// Registered listeners/transports to stream log records to other destinations
  /// (e.g. Sentry, Firebase Crashlytics, local files, etc.).
  static final List<LogCallback> listeners = [];

  DevLogger([this.name = 'DEVLOG']);

  /// Logs a message at [LogLevel.debug].
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Logs a message at [LogLevel.info].
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Logs a message at [LogLevel.warning].
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Logs a message at [LogLevel.error].
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Logs a message at [LogLevel.fatal].
  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (quiet) return;
    if (level.value < minLevel.value) return;

    final record = LogRecord(
      time: DateTime.now(),
      level: level,
      message: message,
      loggerName: name,
      error: error,
      stackTrace: stackTrace,
    );

    // Compose a plain (non-colored) message for developer tools / IDEs.
    final plainMessage = '[${level.label}] $name: $message';

    // 1. Send plain text to developer.log so DevTools / IDEs don't receive raw ANSI codes.
    developer.log(
      plainMessage,
      time: record.time,
      level: level.value,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );

    // 2. Colorize only the terminal output (stdout).
    final ansiColor = enableColors ? level.ansiColor : '';
    final ansiReset = enableColors ? '\x1B[0m' : '';
    final consoleMessage = '$ansiColor$plainMessage$ansiReset';

    // Print the main colored message to stdout.
    print(consoleMessage);

    // If there's an error or stack trace, print them to stdout wrapped with reset codes
    // so they don't leave the terminal in a colored state for following output.
    if (error != null) {
      print('${ansiColor}Error: $error$ansiReset');
    }
    if (stackTrace != null) {
      print('${ansiColor}$stackTrace$ansiReset');
    }

    // 3. Output to custom transports/listeners (production crashlytics, etc.)
    for (final listener in listeners) {
      try {
        listener(record);
      } catch (e, st) {
        // Safeguard against faulty listeners causing logs to crash application code
        developer.log(
          'Error in DevLogger listener callback: $e',
          level: LogLevel.error.value,
          name: 'DevLogger',
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}
