import 'package:flutter/material.dart';

class ShowSnackBar {
  static void show(BuildContext context, String message) {
    // Clean the message to remove any formatting artifacts
    final cleanMessage = message.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cleanMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
