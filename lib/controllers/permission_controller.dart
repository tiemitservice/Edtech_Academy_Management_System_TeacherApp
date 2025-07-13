import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Assuming AuthController is in this path and provides getUserId()
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

class PermissionController extends GetxController {
  // --- Reactive State Variables ---
  // These variables are observable. Any widget wrapped in Obx that uses them
  // will automatically rebuild when their value changes.
  final RxList<Map<String, dynamic>> permissionRequests =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs; // True when fetching data
  final RxBool hasError = false.obs; // True if an error occurred during fetch
  final RxString errorMessage = ''.obs; // Stores the specific error message

  // API Endpoint
  static const String _apiUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/staffpermissions';

  // AuthController instance to get the staff ID.
  // 'late final' means it will be initialized before its first use.
  late final AuthController _authController;

  @override
  void onInit() {
    super.onInit();
    // Retrieve the AuthController instance from GetX's dependency injection.
    // It's assumed AuthController is already registered globally (e.g., in main.dart).
    _authController = Get.find<AuthController>();
    // Automatically fetch permission data when this controller is initialized.
    fetchPermissions();
  }

  /// Determines the appropriate font family based on the text content.
  /// (e.g., 'KantumruyPro' for Khmer characters, 'Inter' for others).
  String getFontFamily(String text) {
    final khmerRegex = RegExp(r'[\u1780-\u17FF\u19E0-\u19FF\uE100-\uE12F]');
    return khmerRegex.hasMatch(text) ? 'KantumruyPro' : 'Inter';
  }

  /// Formats a date or a date range into a user-friendly string.
  /// Examples: "Sunday, Jun 29" or "Jun 29 - Jul 1".
  String _formatDateDisplay(DateTime startDate, [DateTime? endDate]) {
    final end = endDate ?? startDate;

    if (startDate.isAtSameMomentAs(end)) {
      // Single day, display full weekday, month, and day
      return DateFormat('EEEE, MMM d').format(startDate);
    } else {
      // Date range, display month and day for both start and end
      final startFormatted = DateFormat('MMM d').format(startDate);
      final endFormatted = DateFormat('MMM d').format(end);
      return '$startFormatted - $endFormatted';
    }
  }

  /// Fetches permission data from the API for the authenticated staff member.
  /// Updates `permissionRequests`, `isLoading`, `hasError`, and `errorMessage` states.
  Future<void> fetchPermissions() async {
    // Reset states to reflect loading process
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    permissionRequests.clear(); // Clear existing data to show loading state

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

          // Safely parse the 'hold_date' array from the API response
          if (item['hold_date'] is List && item['hold_date'].isNotEmpty) {
            try {
              final dateStrings = List<String>.from(item['hold_date']);
              final startDate = DateTime.tryParse(dateStrings.first);
              final endDate = dateStrings.length > 1
                  ? DateTime.tryParse(dateStrings.last)
                  : startDate;

              if (startDate != null && endDate != null) {
                // Calculate number of days, including start and end days
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

          // Normalize status string for consistent UI display
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
            'isExpanded': false, // Initial state for card expansion in UI
          };
        }).toList();

        // Update the reactive list. This will trigger UI updates in Obx widgets.
        permissionRequests.assignAll(fetchedPermissions);
      } else {
        // Handle API errors (non-2xx status codes)
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
      // Handle network-related errors (e.g., no internet, host unreachable)
      _showErrorSnackbar(
          'Network error: Could not connect to the server. Please check your internet connection.');
      hasError.value = true;
      errorMessage.value = 'Network error: ${e.message}';
      print("HTTP Client Error: $e"); // Log error for debugging
    } catch (e) {
      // Catch any other unexpected errors
      _showErrorSnackbar(
          'An unexpected error occurred. Please try again later.');
      hasError.value = true;
      errorMessage.value = 'An unexpected error occurred: ${e.toString()}';
      print(
          "Unexpected Error fetching permissions: $e"); // Log error for debugging
    } finally {
      // Ensure loading state is turned off after the process completes (or fails)
      isLoading.value = false;
    }
  }

  /// Displays a GetX snackbar for error messages.
  void _showErrorSnackbar(String message) {
    const Color _declineRed = Color(0xFFE74C3C); // Defined locally for snackbar
    const Color _white = Color(0xFFFFFFFF); // Defined locally for snackbar
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _declineRed,
      colorText: _white,
    );
  }

  /// Toggles the `isExpanded` property of a specific permission request.
  /// This causes the `Obx` wrapped `ListView.builder` to re-render the affected card.
  void toggleExpansion(int index) {
    // Ensure the index is within valid bounds of the list
    if (index >= 0 && index < permissionRequests.length) {
      permissionRequests[index]['isExpanded'] =
          !permissionRequests[index]['isExpanded'];
      // Crucial for RxList: Call .refresh() to explicitly notify Obx widgets
      // that an internal property of an item in the list has changed,
      // triggering a UI update for that item.
      permissionRequests.refresh();
    }
  }
}
