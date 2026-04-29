import 'package:flutter/material.dart';

class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.red);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}