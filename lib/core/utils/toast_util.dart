import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Enum for message types
enum ToastType { success, error, normal }

// Utility Function for showing toasts
class ToastUtil {
  /// Shows toast with specified type and message
  static void showToast({required String message, required ToastType type}) {
    Color backgroundColor;
    Toast toastLength;
    Color textColor = Colors.white;

    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green.shade600;
        toastLength = Toast.LENGTH_SHORT;
        break;
      case ToastType.error:
        backgroundColor = Colors.red.shade600;
        toastLength = Toast.LENGTH_LONG;
        break;
      case ToastType.normal:
        backgroundColor = Colors.grey.shade700;
        toastLength = Toast.LENGTH_SHORT;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }

  /// Convenience method for success messages
  static void showSuccess(String message) {
    showToast(message: message, type: ToastType.success);
  }

  /// Convenience method for error messages
  static void showError(String message) {
    showToast(message: message, type: ToastType.error);
  }

  /// Convenience method for normal messages
  static void showNormal(String message) {
    showToast(message: message, type: ToastType.normal);
  }
}