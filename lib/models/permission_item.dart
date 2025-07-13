
// lib/models/permission_item.dart

import 'package:get/get.dart'; // Required for RxBool
import 'package:intl/intl.dart'; // Required for DateFormat
import 'package:school_management_system_teacher_app/models/student.dart'; // Import Student model

/// Represents a single student permission request.
class PermissionItem {
  final String id; // The _id of the permission request
  final String studentId; // ID of the student
  final String sentToStaffId; // ID of the teacher it was sent to ('sent_to' field)
  final String reason;
  final List<DateTime> holdDates; // Parsed dates for the permission period
  String status; // e.g., "pending", "approved", "denied" (from 'permissent_status')
  final DateTime createdAt;

  // UI-specific and reactive state:
  Student? studentDetails; // To hold the fetched Student object
  final RxBool isExpanded; // Reactive property for UI expansion state

  PermissionItem({
    required this.id,
    required this.studentId,
    required this.sentToStaffId,
    required this.reason,
    required this.holdDates,
    required this.status,
    required this.createdAt,
    this.studentDetails,
    RxBool? isExpanded, // Make it nullable in constructor for copyWith
  }) : this.isExpanded = isExpanded ?? false.obs; // Initialize if null

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> holdDateStrings = json['hold_date'] as List<dynamic>? ?? [];
    final List<DateTime> parsedHoldDates = holdDateStrings
        .map((dateStr) => DateTime.tryParse(dateStr.toString()))
        .where((date) => date != null)
        .toList()
        .cast<DateTime>();

    return PermissionItem(
      id: json['_id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      sentToStaffId: json['sent_to'] as String? ?? '',
      reason: json['reason'] as String? ?? 'No reason provided',
      holdDates: parsedHoldDates,
      status: json['permissent_status'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      // When creating from JSON, it's typically not expanded by default
      isExpanded: false.obs,
    );
  }

  // Helper getter to format status for display (e.g., "pending" -> "Pending")
  String get formattedStatus {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // Helper getter to format the date range for display
  String get formattedDateRange {
    if (holdDates.isEmpty) return 'N/A';
    // Sort dates to ensure start and end are correct if the API doesn't guarantee order
    final sortedDates = List<DateTime>.from(holdDates)..sort();

    final startDate = sortedDates.first;
    final endDate = sortedDates.length > 1 ? sortedDates.last : sortedDates.first;

    final dateFormat = DateFormat('EEE, dd/MM/yyyy');

    if (startDate.isAtSameMomentAs(endDate)) {
      return dateFormat.format(startDate);
    } else {
      return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    }
  }

  // copyWith method for immutable updates of PermissionItem instances
  PermissionItem copyWith({
    String? status,
    Student? studentDetails,
    bool? isExpandedValue, // Accept a boolean value here
  }) {
    return PermissionItem(
      id: id,
      studentId: studentId,
      sentToStaffId: sentToStaffId,
      reason: reason,
      holdDates: holdDates,
      status: status ?? this.status,
      createdAt: createdAt,
      studentDetails: studentDetails ?? this.studentDetails,
      isExpanded: RxBool(isExpandedValue ?? this.isExpanded.value), // Create a new RxBool instance based on the provided value
    );
  }
}