import 'package:flutter_devlog/flutter_devlog.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    DevLogger.listeners.clear();
    DevLogger.minLevel = LogLevel.info;
    DevLogger.quiet = false;
  });

  test('basic logging and listener execution', () {
    final logger = DevLogger('test_logger');
    final records = <LogRecord>[];
    
    DevLogger.listeners.add(records.add);

    logger.info('Hello world');
    expect(records.length, 1);
    expect(records.first.message, 'Hello world');
    expect(records.first.level, LogLevel.info);
    expect(records.first.loggerName, 'test_logger');
  });

  test('respects minLevel threshold', () {
    final logger = DevLogger('threshold_logger');
    final records = <LogRecord>[];
    DevLogger.listeners.add(records.add);

    DevLogger.minLevel = LogLevel.warning;

    logger.info('this should be ignored');
    expect(records.isEmpty, true);

    logger.warning('this should be logged');
    expect(records.length, 1);
    expect(records.first.message, 'this should be logged');
    expect(records.first.level, LogLevel.warning);
  });

  test('respects quiet configuration', () {
    final logger = DevLogger('quiet_logger');
    final records = <LogRecord>[];
    DevLogger.listeners.add(records.add);

    DevLogger.quiet = true;

    logger.fatal('silence!');
    expect(records.isEmpty, true);
  });

  test('passes errors and stack traces', () {
    final logger = DevLogger('error_logger');
    final records = <LogRecord>[];
    DevLogger.listeners.add(records.add);

    final error = Exception('something broke');
    final stackTrace = StackTrace.current;

    logger.error('failed task', error, stackTrace);
    
    expect(records.length, 1);
    expect(records.first.error, error);
    expect(records.first.stackTrace, stackTrace);
  });
}
