import 'package:flutter/material.dart';

/// Returns the card background color appropriate for the current theme.
Color cardBackground(ThemeData theme) {
  return theme.brightness == Brightness.dark
      ? const Color(0xFF2D2E30)
      : Colors.white;
}

/// Returns a subtle border side appropriate for the current theme.
BorderSide subtleBorder(ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return BorderSide(
    color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
    width: 1,
  );
}
