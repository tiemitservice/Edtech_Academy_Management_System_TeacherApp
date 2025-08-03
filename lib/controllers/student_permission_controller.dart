// lib/controllers/student_permission_controller.dart
import 'package:flutter/material.dart'; // Keep if you use Material widgets directly, but generally not needed in controllers
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/models/permission_item.dart';
import 'package:school_management_system_teacher_app/models/permission_report.dart';
import 'package:school_management_system_teacher_app/models/student.dart'; // Ensure this model is used/needed
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart'; // Keep if you use AppColors directly in controller, though often moved to UI
import 'package:flutter/foundation.dart'; // For debugPrint

class StudentPermissionController extends GetxController {
  // Services
  final StudentPermissionService _permissionService =
      Get.find<StudentPermissionService>();
  final StudentRepository _studentRepository = Get.find<StudentRepository>();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state variables
  final RxList<PermissionItem> _allStudentPermissions =
      <PermissionItem>[].obs; // Stores the complete, unfiltered list
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isRetrying = false.obs;

  // Reactive variable for current filter type: 'total' or 'pending'
  final RxString currentFilter = 'total'.obs; // Default to showing all

  // Computed RxList that automatically filters based on `currentFilter`
  RxList<PermissionItem> get filteredPermissions {
    if (currentFilter.value == 'pending') {
      return _allStudentPermissions
          .where((p) => p.status.toLowerCase() == 'pending')
          .toList()
          .obs; // Return a new RxList
    } else {
      return _allStudentPermissions; // Return the full list
    }
  }

  // Reactive variables for permission counts (now updated from _allStudentPermissions)
  final RxInt totalPermissions = 0.obs;
  final RxInt pendingPermissions = 0.obs;
  final RxInt approvedPermissions = 0.obs;
  final RxInt deniedPermissions = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Use `ever` to react to changes in `_allStudentPermissions` for updating counts
    ever(_allStudentPermissions, (_) => _updatePermissionCounts());

    _studentRepository.fetchAllStudents().then((_) {
      fetchStudentPermissions(); // Fetch permissions after students are loaded
    }).catchError((e) {
      errorMessage.value =
          "Failed to load student data: ${e.toString().replaceFirst('Exception: ', '')}";
      isLoading.value = false;
    });
  }

  // Updates permission counts based on the _allStudentPermissions list
  void _updatePermissionCounts() {
    totalPermissions.value = _allStudentPermissions.length;
    pendingPermissions.value = _allStudentPermissions
        .where((p) => p.status.toLowerCase() == 'pending')
        .length;
    approvedPermissions.value = _allStudentPermissions
        .where((p) => p.status.toLowerCase() == 'approved')
        .length;
    deniedPermissions.value = _allStudentPermissions
        .where((p) =>
            p.status.toLowerCase() == 'denied' ||
            p.status.toLowerCase() == 'rejected')
        .length;
  }

  // Fetches all student permissions and updates the main list
  Future<void> fetchStudentPermissions() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final teacherStaffId = await _authController.getStaffId();
      if (teacherStaffId.isEmpty) {
        errorMessage.value = "Teacher Staff ID not found.";
        isLoading.value = false;
        return;
      }
      final allPermissions = await _permissionService.fetchAllPermissions();
      final filteredByTeacherPermissions = allPermissions
          .where((p) => p.sentToStaffId == teacherStaffId)
          .toList();

      final List<PermissionItem> enrichedPermissions = [];
      for (var permission in filteredByTeacherPermissions) {
        final Student? student =
            await _studentRepository.getStudentById(permission.studentId);
        enrichedPermissions.add(permission.copyWith(studentDetails: student));
      }
      _allStudentPermissions
          .assignAll(enrichedPermissions); // Update the main list
      // _updatePermissionCounts() will be called automatically by `ever` listener
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> autoRetryFetch() async {
    isRetrying.value = true;
    await fetchStudentPermissions();
    isRetrying.value = false;
  }

  /// Sets the filter for the displayed permissions.
  /// [filter]: 'total' to show all, 'pending' to show only pending.
  void setFilter(String filter) {
    if (currentFilter.value != filter) {
      // Only update if the filter is actually changing
      currentFilter.value = filter;
      debugPrint('Permission filter set to: ${currentFilter.value}');
    }
  }

  /// Updates the status of a permission and creates a report if approved/denied.
  /// [permission]: The full permission item being updated.
  /// [newStatus]: The new status ("approved" or "denied").
  Future<void> updatePermissionStatus(
      PermissionItem permission, String newStatus) async {
    debugPrint(
        'Attempting to update permission ${permission.id} to $newStatus');
    try {
      // Step 1: Update the original permission status on the backend
      await _permissionService.updatePermissionStatus(permission.id, newStatus);

      // Step 2: If approved or denied, create a report.
      final lowerCaseStatus = newStatus.toLowerCase();
      if (lowerCaseStatus == "approved" || lowerCaseStatus == "denied") {
        debugPrint('Status is final, creating a report...');
        try {
          final teacherStaffId = await _authController.getStaffId();
          if (teacherStaffId.isNotEmpty) {
            final report = PermissionReport(
              studentId: permission.studentId,
              reason: permission.reason,
              permissionStatus: lowerCaseStatus,
              approveBy: teacherStaffId, // The current teacher is the approver
            );
            await _permissionService.createPermissionReport(report);
            debugPrint('Successfully created permission report.');
          } else {
            debugPrint('Could not create report: Teacher Staff ID not found.');
          }
        } catch (e) {
          // Log the report creation error, but don't block the UI feedback
          debugPrint('!!! FAILED to create permission report: $e');
        }
      }

      // Step 3: Update the local UI for immediate feedback
      // Find the index in _allStudentPermissions to update the original data
      final index =
          _allStudentPermissions.indexWhere((p) => p.id == permission.id);
      if (index != -1) {
        _allStudentPermissions[index] = _allStudentPermissions[index]
            .copyWith(status: newStatus.toLowerCase());
        // _updatePermissionCounts() will be called automatically by `ever` listener
      }

      Get.snackbar(
        'Success',
        'Permission ${newStatus.capitalizeFirst}!', // Assumes you have capitalizeFirst extension
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('!!! ERROR updating permission status: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Failed to update permission: ${e.toString().replaceFirst('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    }
  }
}
