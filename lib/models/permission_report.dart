// lib/models/permission_report.dart

/// Represents the data payload for creating a student permission report.
/// This is used when sending data to the server after a permission is approved or denied.
class PermissionReport {
  final String studentId;
  final String reason;
  final String permissionStatus;
  final String approveBy; // The staff ID of the teacher who took the action

  PermissionReport({
    required this.studentId,
    required this.reason,
    required this.permissionStatus,
    required this.approveBy,
  });

  /// Converts this object into a JSON format for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'reason': reason,
      'permission_status': permissionStatus,
      'approve_by': approveBy,
    };
  }
}
