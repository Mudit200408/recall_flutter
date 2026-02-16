import 'package:flutter/material.dart';

/// App-wide accent color based on user mode.
/// - Guest (local AI): Cyan `#00FFE1`
/// - Authenticated (cloud AI): Lime `#CCFF00`
Color accentColor(bool isGuest) {
  return isGuest
      ? const Color.fromARGB(255, 0, 255, 225)
      : const Color(0xFFCCFF00);
}
