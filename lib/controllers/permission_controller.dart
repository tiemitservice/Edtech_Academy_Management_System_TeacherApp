import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // Added import

class PermissionController extends GetxController {
  final RxList<Map<String, dynamic>> permissionRequests =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _apiUrl =
      'http://188.166.242.109:5000/api/staffpermissions';

  late final AuthController _authController;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    fetchPermissions();
  }

  /// Determines the appropriate font family based on the text content.
  /// Uses 'KantumruyPro' (from AppFonts) for Khmer characters, 'Inter' for others.
  String getFontFamily(String text) {
    final khmerRegex = RegExp(r'[\u1780-\u17FF\u19E0-\u19FF\uE100-\uE12F]');
    // Assuming AppFonts.fontFamily is your primary Khmer font.
    // Use 'Inter' as a common Latin fallback, or another suitable font.
    return khmerRegex.hasMatch(text) ? AppFonts.fontFamily : 'Inter';
  }

  /// Formats a date or a date range into a user-friendly string.
  /// Examples: "Sunday, Jun 29" or "Jun 29 - Jul 1".
  String _formatDateDisplay(DateTime startDate, [DateTime? endDate]) {
    final end = endDate ?? startDate;

    if (startDate.isAtSameMomentAs(end)) {
      return DateFormat('EEEE, MMM d').format(startDate);
    } else {
      final startFormatted = DateFormat('MMM d').format(startDate);
      final endFormatted = DateFormat('MMM d').format(end);
      return '$startFormatted - $endFormatted';
    }
  }

  /// Fetches permission data from the API for the authenticated staff member.
  /// Updates `permissionRequests`, `isLoading`, `hasError`, and `errorMessage` states.
  Future<void> fetchPermissions() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    permissionRequests.clear();

    try {
      final String staffId = await _authController.getUserId();
      if (staffId.isEmpty) {
        throw Exception("Staff ID not found. Please log in again.");
      }

      final response = await http.get(Uri.parse('$_apiUrl?staff=$staffId'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final List<dynamic> responseData = responseBody['data'] ?? [];

        final List<Map<String, dynamic>> fetchedPermissions =
            responseData.map((item) {
          String formattedDate = 'N/A';
          String formattedDateDisplay = 'N/A';
          String daysText = 'N/A';

          if (item['hold_date'] is List && item['hold_date'].isNotEmpty) {
            try {
              final dateStrings = List<String>.from(item['hold_date']);
              final startDate = DateTime.tryParse(dateStrings.first);
              final endDate = dateStrings.length > 1
                  ? DateTime.tryParse(dateStrings.last)
                  : startDate;

              if (startDate != null && endDate != null) {
                final daysCount = endDate.difference(startDate).inDays + 1;
                daysText = 'Ask for $daysCount day${daysCount == 1 ? '' : 's'}';
                formattedDateDisplay = _formatDateDisplay(startDate, endDate);
                formattedDate = startDate.isAtSameMomentAs(endDate)
                    ? DateFormat('EEEE, dd/MM/yyyy').format(startDate)
                    : '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';
              } else {
                formattedDate = 'Invalid Date';
                formattedDateDisplay = 'Invalid Date';
                daysText = 'Invalid Date';
              }
            } catch (e) {
              print("Error parsing hold_date: $e for item: $item");
              formattedDate = 'Invalid Date';
              formattedDateDisplay = 'Invalid Date';
              daysText = 'Invalid Date';
            }
          }

          String status = 'Unknown';
          final String rawStatus =
              item['status']?.toString().toLowerCase() ?? 'unknown';
          if (rawStatus == 'approved' || rawStatus == 'accepted') {
            status = 'Approved';
          } else if (rawStatus == 'pending') {
            status = 'Pending';
          } else if (rawStatus == 'rejected' || rawStatus == 'denied') {
            status = 'Rejected';
          }

          return {
            'id': item['_id'],
            'date_full': formattedDate,
            'formatted_date_display': formattedDateDisplay,
            'days_text': daysText,
            'reason': item['reason'] ?? 'No reason provided',
            'status': status,
            'isExpanded': false,
          };
        }).toList();

        permissionRequests.assignAll(fetchedPermissions);
      } else {
        String errorMsg =
            'Failed to load permissions. Status: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson != null && errorJson['message'] != null) {
            errorMsg = errorJson['message'];
          }
        } catch (_) {
          // If JSON parsing of error body fails, use generic message
        }
        throw http.ClientException(errorMsg);
      }
    } on http.ClientException catch (e) {
      _showErrorSnackbar(
          'Network error: Could not connect to the server. Please check your internet connection.');
      hasError.value = true;
      errorMessage.value = 'Network error: ${e.message}';
      print("HTTP Client Error: $e");
    } catch (e) {
      _showErrorSnackbar(
          'An unexpected error occurred. Please try again later.');
      hasError.value = true;
      errorMessage.value = 'An unexpected error occurred: ${e.toString()}';
      print("Unexpected Error fetching permissions: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.declineRed,
      colorText: Colors.white,
    );
  }

  /// Toggles the `isExpanded` property of a specific permission request.
  /// Calls `permissionRequests.refresh()` to ensure UI update.
  void toggleExpansion(int index) {
    if (index >= 0 && index < permissionRequests.length) {
      permissionRequests[index]['isExpanded'] =
          !permissionRequests[index]['isExpanded'];
      permissionRequests.refresh(); // Crucial for RxList internal item changes
    }
  }
}