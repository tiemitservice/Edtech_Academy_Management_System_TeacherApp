// lib/utils/app_constants.dart

import 'package:flutter/material.dart';

// Unified AppColors for consistency across the application
class AppColors {
  static const Color primaryBlue = Color(0xFF1469C7);
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color cardBackground = Colors.white;
  static const Color darkText = Color(0xFF2C3E50);
  static const Color mediumText = Color(0xFF7F8C8D);
  static const Color borderGrey = Color(0xFFE0E6ED);
  static const Color declineRed = Color(0xFFE74C3C); // Used for errors/denied
  static const Color successGreen =
      Color(0xFF27AE60); // Used for success/approved
  static const Color pendingOrange =
      Color(0xFFF39C12); // Used for pending status
  static const Color skeletonBaseColor = Color(0xFFE0E0E0);
  static const Color skeletonHighlightColor = Color(0xFFF0F0F0);
  static const Color accentBlue =
      Color(0xFF3498DB); // Example additional accent color
}

// Unified AppFonts for consistency across the application
class AppFonts {
  static const String fontFamily =
      'KantumruyPro'; // Ensure this font is correctly set up in pubspec.yaml
}

// Unified AppDurations for common animation/snackbar durations
class AppDurations {
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration apiTimeout =
      Duration(seconds: 15); // General API timeout
}

// Unified AppAssets for common asset paths
class AppAssets {
  static const String teacherCheckSvg =
      'assets/images/onboarding/teacher_check.svg';
  static const String teacherReadSvg =
      'assets/images/onboarding/teacher_read.svg';
  static const String emptyStateIllustration =
      'assets/images/illustrations/empty_state.svg'; // Placeholder for a generic empty state SVG
  static const String networkErrorIllustration =
      'assets/images/illustrations/network_error.svg'; // Placeholder for network error SVG
}

// Unified AppApi for API endpoints
class AppApi {
  static const String baseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api';
  static const String permissionsEndpoint = '$baseUrl/student_permissions';
  static const String studentsEndpoint = '$baseUrl/students';
  static const String classesEndpoint = '$baseUrl/classes';
  static const String subjectsEndpoint = '$baseUrl/subjects';
}
