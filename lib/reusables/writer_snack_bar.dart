import 'package:flutter/material.dart';

import 'package:writer_plus/constants/constants.dart';

class WriterSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Constants.headingTS.copyWith(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: isError
            ? Colors.redAccent.shade700
            : Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 65),
      ),
    );
  }
}
