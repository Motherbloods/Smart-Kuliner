import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    int? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: duration ?? 0),
      ),
    );
  }

  static void showWarningSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    int? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: duration ?? 0), // default 2 detik jika null
      ),
    );
  }
}
