// lib/services/student_permission_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_management_system_teacher_app/models/permission_item.dart'; // Import PermissionItem

/// A service class for managing student permission requests.
class StudentPermissionService {
  final String _baseUrl =
      'https://edtech-academy-management-system-server.onrender.com/api/student_permissions';

  /// Fetches all student permission requests.
  /// Returns a list of [PermissionItem] objects.
  Future<List<PermissionItem>> fetchAllPermissions() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> rawPermissions = jsonData['data'];

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
        Uri.parse('$_baseUrl/$permissionId'),
        headers: {'Content-Type': 'application/json'},
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
}
