// lib/services/student_permission_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/models/permission_item.dart';
import 'package:school_management_system_teacher_app/models/permission_report.dart'; // Import the new report model

/// A service class for managing student permission requests.
class StudentPermissionService {
  final String _permissionsBaseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/student_permissions';
  final String _reportsBaseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/studentpermissionreports';

  /// Fetches all student permission requests.
  /// Returns a list of [PermissionItem] objects.
  Future<List<PermissionItem>> fetchAllPermissions() async {
    try {
      final response = await http.get(Uri.parse(_permissionsBaseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        // Ensure 'data' key exists and is a list
        final List<dynamic> rawPermissions = jsonData['data'] as List<dynamic>? ?? [];

        return rawPermissions
            .map((rawPermission) => PermissionItem.fromJson(rawPermission))
            .toList();
      } else {
        throw Exception(
            'Failed to load student permissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
          'An error occurred while fetching student permissions: $e');
    }
  }

  /// Updates the status of a specific student permission request.
  /// [permissionId]: The ID of the permission request to update.
  /// [newStatus]: The new status to set (e.g., "approved", "denied").
  Future<void> updatePermissionStatus(
      String permissionId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$_permissionsBaseUrl/$permissionId'),
        headers: {'Content-Type': 'application/json'},
        // Note: The backend seems to expect 'permissent_status'
        body: json.encode({'permissent_status': newStatus}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update permission status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating permission status: $e');
    }
  }

  /// Creates a new permission report when a permission is approved or denied.
  /// [report]: The report object containing all necessary data.
  Future<void> createPermissionReport(PermissionReport report) async {
    try {
      final response = await http.post(
        Uri.parse(_reportsBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(report.toJson()),
      );

      // A successful creation usually returns 201 (Created) or 200 (OK).
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
            'Failed to create permission report: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Re-throw the exception to be handled by the controller.
      throw Exception('Error creating permission report: $e');
    }
  }
}
