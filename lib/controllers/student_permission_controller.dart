import 'package:get/get.dart'; // Import Get for Rx features
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// Assuming AuthController is available for getting staff ID
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

// --- Data Models (Refined for API and display) ---

// This Student model is used within the PermissionItem.
// Ensure it's consistent with your actual Student model if defined elsewhere.
class Student {
  final String id;
  final String name; // Assuming this is the English name (eng_name)
  final String gender;
  final String? avatarUrl;

  Student({
    required this.id,
    required this.name,
    required this.gender,
    this.avatarUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? '',
      name: json['eng_name'] ?? 'Unknown Student', // Use eng_name from API
      gender: json['gender'] ?? 'N/A',
      avatarUrl: json['image'],
    );
  }
}

class PermissionItem {
  final String
      id; // This is the _id from the API for the permission request itself
  final String studentId;
  final String sentToStaffId; // Corresponds to 'sent_to' in API
  final String reason;
  final List<DateTime> holdDates; // Parsed DateTimes from 'hold_date'
  String status; // 'pending', 'approved', 'denied' (from 'permissent_status')
  final DateTime createdAt;

  // Additional field to store fetched student details
  Student? studentDetails;

  // RxBool for UI expansion state
  final RxBool isExpanded; // <--- This needs to be a final RxBool

  PermissionItem({
    required this.id,
    required this.studentId,
    required this.sentToStaffId,
    required this.reason,
    required this.holdDates,
    required this.status,
    required this.createdAt,
    this.studentDetails, // Allow nullable initial value
    bool initialIsExpanded = false, // Add a parameter for initial state
  }) : isExpanded = initialIsExpanded.obs; // Initialize the RxBool here

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> holdDateStrings = json['hold_date'] ?? [];
    final List<DateTime> parsedHoldDates = holdDateStrings
        .map((dateStr) =>
            DateTime.tryParse(dateStr.toString())!) // Ensure dateStr is String
        // ignore: unnecessary_null_comparison
        .where((date) => date != null)
        .toList()
        .cast<DateTime>();

    return PermissionItem(
      id: json['_id'] ?? '',
      studentId: json['studentId'] ?? '',
      sentToStaffId: json['sent_to'] ?? '',
      reason: json['reason'] ?? 'No reason provided',
      holdDates: parsedHoldDates,
      status: json['permissent_status'] ?? 'unknown', // Use 'permissent_status'
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      initialIsExpanded:
          false, // Default to not expanded when created from JSON
    );
  }

  // Helper to format status for display (e.g., "pending" -> "Pending")
  String get formattedStatus {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // Helper to format hold_date for display (e.g., "Mon, 10/06/2025 - Tue, 11/06/2025")
  String get formattedDateRange {
    if (holdDates.isEmpty) return 'N/A';
    final startDate = holdDates.first;
    final endDate = holdDates.length > 1 ? holdDates.last : holdDates.first;

    final dateFormat = DateFormat('EEE, dd/MM/yyyy');

    if (startDate.isAtSameMomentAs(endDate)) {
      return dateFormat.format(startDate);
    } else {
      return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    }
  }

  // Helper to update status (useful for local UI updates before/after API call)
  PermissionItem copyWith({String? status, bool? isExpanded}) {
    return PermissionItem(
      id: id,
      studentId: studentId,
      sentToStaffId: sentToStaffId,
      reason: reason,
      holdDates: holdDates,
      status: status ?? this.status,
      createdAt: createdAt,
      studentDetails: studentDetails, // Preserve existing student details
      initialIsExpanded: isExpanded ??
          this.isExpanded.value, // Preserve or update expansion state
    );
  }
}

// --- Controller for Student Permissions Screen ---
class StudentPermissionController extends GetxController {
  // --- Reactive State Variables ---
  final RxList<PermissionItem> studentPermissions = <PermissionItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxMap<String, Student> studentDetailsMap =
      <String, Student>{}.obs; // Cache student details by ID

  // --- API Endpoints ---
  final String _permissionsApiUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/student_permissions';
  final String _studentsApiUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/students'; // Assuming API to get student details

  late final AuthController _authController;

  // --- Font Family Constant (for Snackbars/Messages) ---
  static const String _fontFamily = 'NotoSerifKhmer'; // Consistent font
  static const Color _errorRed = Color(0xFFDC3545);
  static const Color _successGreen = Color(0xFF27AE60);

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    fetchStudentPermissions(); // Trigger initial data fetch when controller is created
  }

  // Helper to provide font family for GetX snackbars/dialogs
  String getFontFamily() => _fontFamily;

  // --- Main Data Fetching Logic ---
  Future<void> fetchStudentPermissions() async {
    isLoading.value = true; // Set loading state to true
    errorMessage.value = ''; // Clear any previous error messages
    studentPermissions.clear(); // Clear existing data list

    try {
      final String staffId = await _authController
          .getUserId(); // Get the authenticated teacher's staff ID
      if (staffId.isEmpty) {
        throw Exception("Staff ID not found. Please log in again.");
      }

      // 1. Fetch all student permissions, filtered by the teacher's ID
      final permissionsResponse =
          await http.get(Uri.parse('$_permissionsApiUrl?sent_to=$staffId'));

      if (permissionsResponse.statusCode == 200) {
        final Map<String, dynamic> decodedData =
            json.decode(permissionsResponse.body);
        final List<dynamic> permissionsJson = decodedData['data'] ?? [];

        // Collect all unique student IDs from the fetched permissions
        final Set<String> uniqueStudentIds = permissionsJson
            .map((p) => p['studentId'].toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        // 2. Fetch details for all unique students involved in these permissions
        await _fetchStudentDetailsForPermissions(uniqueStudentIds.toList());

        // 3. Process each permission item and attach its corresponding student details
        final List<PermissionItem> fetchedPermissions =
            permissionsJson.map((pJson) {
          final permission = PermissionItem.fromJson(pJson);
          permission.studentDetails = studentDetailsMap[
              permission.studentId]; // Attach student data from cache
          // No need to set isExpanded on pJson. It's handled by the PermissionItem constructor.
          return permission;
        }).toList();

        studentPermissions
            .assignAll(fetchedPermissions); // Update the reactive list
      } else {
        throw Exception(
            "Failed to load permissions: Server responded with status ${permissionsResponse.statusCode}.");
      }
    } on http.ClientException catch (e) {
      // Handle network-related errors (e.g., no internet connection)
      errorMessage.value = "Network Error: ${e.message}";
      _showSnackbar('Network Error',
          'Could not connect to the server. Please check your internet connection.');
    } catch (e) {
      // Handle any other unexpected errors
      errorMessage.value = "An unexpected error occurred: ${e.toString()}";
      _showSnackbar(
          'Error', 'An unexpected error occurred while fetching permissions.');
      print("Error fetching student permissions: $e"); // Log for debugging
    } finally {
      isLoading.value = false; // Always set loading to false in finally block
    }
  }

  // Helper method to fetch student details for a list of student IDs
  Future<void> _fetchStudentDetailsForPermissions(
      List<String> studentIds) async {
    if (studentIds.isEmpty) return;

    // This is an example assuming /api/students endpoint returns ALL students.
    // A more efficient approach for large datasets would be:
    // 1. A bulk GET endpoint like /api/students?ids=id1,id2,id3
    // 2. Individual GET requests if bulk is not supported, but be mindful of rate limits.
    try {
      final response = await http.get(Uri.parse(_studentsApiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> studentsJson = decodedData['data'] ?? [];

        // Clear existing cache and populate with fetched student data
        studentDetailsMap.clear();
        for (var sJson in studentsJson) {
          final student = Student.fromJson(sJson);
          studentDetailsMap[student.id] = student;
        }
      } else {
        print(
            "Warning: Failed to fetch student details: Status ${response.statusCode}");
        // Log a warning, but don't stop. Permissions without student names might still be displayed.
      }
    } catch (e) {
      print("Warning: Error fetching student details: $e");
      // Log error, but don't halt permission display
    }
  }

  // --- Action Handlers: Update Permission Status ---
  Future<void> updatePermissionStatus(
      String permissionId, String newStatus, String classId) async {
    // Added classId
    // Show a loading indicator (e.g., for the whole screen or specific card)
    // Here, we're using the main screen's isLoading for simplicity, but you could add a per-card loader.
    isLoading.value = true;
    try {
      final response = await http.patch(
        Uri.parse(
            '$_permissionsApiUrl/$permissionId'), // PATCH request to specific permission ID
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'permissent_status': newStatus.toLowerCase()}), // Send new status
      );

      if (response.statusCode == 200) {
        _showSnackbar('Success',
            'Permission status updated to ${newStatus.capitalizeFirst!}.',
            isSuccess: true);
        // Optimistically update the UI list or re-fetch all data to ensure freshness
        final index =
            studentPermissions.indexWhere((p) => p.id == permissionId);
        if (index != -1) {
          // Create a new PermissionItem instance with the updated status
          // and preserve the current isExpanded state
          final currentPermission = studentPermissions[index];
          studentPermissions[index] = currentPermission.copyWith(
              status: newStatus.toLowerCase(),
              isExpanded: currentPermission.isExpanded.value);
          studentPermissions
              .refresh(); // Crucial to force Obx to re-render the list item
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final msg = errorBody['message'] ?? 'Failed to update status.';
        _showSnackbar('Error', 'Failed to update permission: $msg');
      }
    } on http.ClientException catch (e) {
      _showSnackbar(
          'Network Error', 'Could not connect to update status: ${e.message}');
    } catch (e) {
      _showSnackbar('Error', 'An unexpected error occurred: ${e.toString()}');
      print("Error updating permission status: $e"); // Debugging
    } finally {
      isLoading.value = false; // Hide loading indicator
    }
  }

  // --- Snackbar Utility ---
  void _showSnackbar(String title, String message, {bool isSuccess = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isSuccess ? _successGreen : _errorRed,
      colorText: Colors.white,
      messageText: Text(message,
          style: TextStyle(fontFamily: _fontFamily, color: Colors.white)),
      titleText: Text(title,
          style: TextStyle(
              fontFamily: _fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold)),
      duration: const Duration(seconds: 3),
    );
  }
}
