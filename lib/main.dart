// main.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'dart:async';
import 'package:logger/logger.dart';

void main() {
  final logger = Logger();
  const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Show a custom error widget in release mode
    if (kReleaseMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Scaffold(
          body: Center(
            child: Text('Oops, something went wrong!'),
          ),
        );
      };
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // You can add your logging here if you want to log all Flutter errors
      logger.e('Caught Flutter error: ${details.exception}',
          stackTrace: details.stack);
    };

    runApp(const App());
  }, (error, stack) {
    logger.e('Caught unhandled error: $error', stackTrace: stack);
  });
}