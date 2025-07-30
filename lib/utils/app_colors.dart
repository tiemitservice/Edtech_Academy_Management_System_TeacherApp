import 'package:flutter/material.dart';

/// Defines a set of consistent color constants used throughout the application.
class AppColors {
  static const Color primaryBlue = Color(0xFF1468C7);
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color cardBackground = Colors.white;
  static const Color darkText = Color(0xFF2C3E50);
  static const Color mediumText = Color(0xFF7F8C8D);
  static const Color borderGrey = Color(0xFFE0E6ED);
  static const Color declineRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color pendingOrange = Color(0xFFF39C12);
  static const Color skeletonBaseColor = Color(0xFFE0E0E0);
  static const Color skeletonHighlightColor = Color(0xFFF0F0F0);
  static const Color lightFillColor = Color(0xFFF4F7F9);
}

class AppFonts {
  static const String fontFamily =
      'Suwannaphum'; // IMPORTANT: Ensure this matches the 'family' name in your pubspec.yaml
}
