import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_synergy/core/utils/logger.dart';

/// Sets up global error handling for both Flutter framework errors
/// and uncaught async errors.
///
/// Call [GlobalErrorHandler.init] in `main()` before `runApp`.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static void init(VoidCallback runApp) {
    // Catch Flutter framework errors (e.g. build / layout / paint).
    FlutterError.onError = (details) {
      AppLogger.error(
        'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      // In debug mode, also print to console.
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Catch errors that escape the Flutter framework (Futures, Isolates).
    runZonedGuarded(runApp, (error, stackTrace) {
      AppLogger.error(
        'Uncaught async error',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
}
