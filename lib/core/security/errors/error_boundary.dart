import 'package:flutter/material.dart';

class ErrorBoundary {
  static void handleError(
      BuildContext context, dynamic error, StackTrace stack) {
    print('❌ Error: $error');
    print('📚 Stack: $stack');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getUserFriendlyMessage(error)),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static String _getUserFriendlyMessage(dynamic error) {
    if (error is ArgumentError) return 'Invalid data: ${error.message}';
    if (error is FormatException)
      return 'Data format error. Please check your input.';
    if (error is StateError) return 'Internal error. Please restart the app.';
    return 'Something went wrong. Please try again.';
  }

  static Future<T?> safeCall<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    T? fallback,
  }) async {
    try {
      return await operation();
    } catch (e, s) {
      handleError(context, e, s);
      return fallback;
    }
  }
}
