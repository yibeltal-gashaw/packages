# flutter_devlog

A production-grade, zero-dependency, highly performant custom logging utility for Dart and Flutter applications.

## Features
- **Zero Runtime Dependencies**: No bloated third-party logging packages.
- **Native Flutter Integration**: Leverages `dart:developer`'s `log` to integrate directly with Flutter DevTools.
- **ANSI Colors**: Colorized terminal output in development mode.
- **Production Event Listeners**: Easily dispatch logs to Sentry, Firebase Crashlytics, or save them locally.
- **Environment-Aware**: Respects build/environment-level configuration parameters like `QUIET` or `minLevel`.

## Usage

```dart
import 'package:flutter_devlog/flutter_devlog.dart';

final logger = DevLogger('AuthService');

void main() {
  // 1. Configure global options
  DevLogger.minLevel = LogLevel.info;
  DevLogger.enableColors = true;

  // 2. Add custom production transports/listeners
  DevLogger.listeners.add((record) {
    if (record.level >= LogLevel.error) {
      // Forward to Crashlytics / Sentry / analytics
      // FirebaseCrashlytics.instance.recordError(record.error, record.stackTrace, reason: record.message);
    }
  });

  // 3. Log events
  logger.info('User successfully logged in');
  logger.warning('Deprecated API endpoint called');
  
  try {
    throw Exception('Database connection lost');
  } catch (e, stack) {
    logger.error('Failed to query database', e, stack);
  }
}
```
