import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Import for Get.snackbar, Colors
import 'package:school_management_system_teacher_app/models/permission_item.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:async'; // Required for Timer

class StudentPermissionController extends GetxController {
  // Services
  final StudentPermissionService _permissionService = Get.find<StudentPermissionService>();
  final StudentRepository _studentRepository = Get.find<StudentRepository>();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state variables
  final RxList<PermissionItem> studentPermissions = <PermissionItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // Reactive variables for permission counts
  final RxInt totalPermissions = 0.obs;
  final RxInt pendingPermissions = 0.obs;
  final RxInt approvedPermissions = 0.obs;
  final RxInt deniedPermissions = 0.obs;

  // Polling mechanism
  Timer? _pollingTimer;
  // Define how often you want to poll the server. E.g., every 15 seconds.
  static const Duration _pollingInterval = Duration(seconds: 15);

  @override
  void onInit() {
    super.onInit();
    // Pre-fetch all students when controller initializes to populate the repository's cache.
    // This makes subsequent lookups by ID fast, avoiding N+1 network calls.
    _studentRepository.fetchAllStudents().then((_) {
      fetchStudentPermissions(); // Perform initial fetch of permissions
      _startPolling(); // Start polling after the initial data is loaded
    }).catchError((e) {
      errorMessage.value = "Failed to load student data: ${e.toString().replaceFirst('Exception: ', '')}";
      isLoading.value = false;
      debugPrint('Error pre-fetching all students: $e');
      Get.snackbar(
        'Data Loading Error',
        'Could not load essential student data: ${errorMessage.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    });
  }

  @override
  void onClose() {
    _stopPolling(); // IMPORTANT: Stop the timer when the controller is closed to prevent memory leaks
    super.onClose();
  }

  /// Starts the periodic polling for student permissions.
  void _startPolling() {
    _pollingTimer?.cancel(); // Cancel any existing timer to prevent duplicates
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      debugPrint('Polling for student permissions...');
      // Only fetch if not already loading to prevent overlapping API calls
      if (!isLoading.value) {
        fetchStudentPermissions();
      }
    });
  }

  /// Stops the periodic polling.
  void _stopPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
      debugPrint('Polling stopped.');
    }
  }

  /// Calculates and updates the permission counts based on the current list.
  void _updatePermissionCounts() {
    totalPermissions.value = studentPermissions.length;
    pendingPermissions.value = studentPermissions
        .where((p) => p.status.toLowerCase() == 'pending')
        .length;
    approvedPermissions.value = studentPermissions
        .where((p) => p.status.toLowerCase() == 'approved')
        .length;
    deniedPermissions.value = studentPermissions
        .where((p) => p.status.toLowerCase() == 'denied' || p.status.toLowerCase() == 'rejected')
        .length;
    debugPrint('--- PERMISSION COUNTS UPDATED ---');
    debugPrint('Total: ${totalPermissions.value}, Pending: ${pendingPermissions.value}, Approved: ${approvedPermissions.value}, Denied: ${deniedPermissions.value}');
    debugPrint('-------------------------------');
  }

  /// Fetches all relevant student permissions and enriches them with student details.
  Future<void> fetchStudentPermissions() async {
    // Only set isLoading to true if it's not already true from a previous ongoing fetch
    if (!isLoading.value) {
      isLoading.value = true;
    }
    errorMessage.value = ''; // Clear any previous error
    debugPrint('Fetching student permissions...');

    try {
      final teacherStaffId = await _authController.getStaffId();
      if (teacherStaffId.isEmpty) {
        errorMessage.value = "Teacher Staff ID not found. Please log in.";
        isLoading.value = false;
        debugPrint('Error: Teacher Staff ID is empty.');
        Get.snackbar(
          'Authentication Required',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.declineRed,
          colorText: Colors.white,
        );
        return;
      }
      debugPrint('Teacher Staff ID: $teacherStaffId');

      // 1. Fetch all permission requests
      final List<PermissionItem> allPermissions =
          await _permissionService.fetchAllPermissions();
      debugPrint('Fetched ${allPermissions.length} raw permissions.');

      // 2. Filter permissions relevant to this teacher (sent_to matches teacherStaffId)
      final List<PermissionItem> filteredPermissions = allPermissions
          .where((p) => p.sentToStaffId == teacherStaffId)
          .toList();
      debugPrint('Filtered to ${filteredPermissions.length} permissions for this teacher.');

      if (filteredPermissions.isEmpty) {
        studentPermissions.assignAll([]); // Clear list if no permissions found
        _updatePermissionCounts(); // Update counts even if empty
        isLoading.value = false;
        debugPrint('No permissions found for this teacher.');
        return;
      }

      // 3. Enrich filtered permissions with student details using StudentRepository
      final List<PermissionItem> enrichedPermissions = [];
      for (var permission in filteredPermissions) {
        // Use the repository to get student details. It should be fast if pre-fetched.
        final Student? student = await _studentRepository.getStudentById(permission.studentId);
        if (student != null) {
          // If student details are found, create a new permission item with enriched details
          enrichedPermissions.add(permission.copyWith(studentDetails: student));
          debugPrint('   Permission ID: ${permission.id} - Student details found: ${student.engName} (ID: ${student.id})');
        } else {
          // If student details are not found, still add the permission but with null studentDetails
          // This ensures the permission item is still displayed, even if student info is missing.
          enrichedPermissions.add(permission.copyWith(studentDetails: null));
          debugPrint('   Permission ID: ${permission.id} - Student details NOT FOUND in repository for ID: ${permission.studentId}');
        }
      }

      // Update the reactive list. GetX will automatically trigger UI updates.
      studentPermissions.assignAll(enrichedPermissions);
      _updatePermissionCounts(); // Recalculate counts after data is loaded
      debugPrint('Finished enriching permissions. Total permissions in RxList: ${studentPermissions.length}');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      debugPrint('!!! ERROR in fetchStudentPermissions: ${errorMessage.value}');
      Get.snackbar(
        'Error',
        'Failed to load permissions: ${errorMessage.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false; // Always set loading to false when done
    }
  }

  /// Updates the status of a specific permission and refreshes the list.
  Future<void> updatePermissionStatus(String permissionId, String newStatus) async {
    debugPrint('Attempting to update permission status for $permissionId to $newStatus');
    try {
      await _permissionService.updatePermissionStatus(permissionId, newStatus);

      // Update the status of the permission item locally to provide immediate feedback
      final index = studentPermissions.indexWhere((p) => p.id == permissionId);
      if (index != -1) {
        studentPermissions[index] =
            studentPermissions[index].copyWith(status: newStatus.toLowerCase());
        _updatePermissionCounts(); // Recalculate counts after local status change
        debugPrint('Permission $permissionId status updated to $newStatus locally and counts recalculated.');
      }

      Get.snackbar(
        'Success',
        'Permission ${newStatus.capitalizeFirst}!', // CapitalizeFirst for better display
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