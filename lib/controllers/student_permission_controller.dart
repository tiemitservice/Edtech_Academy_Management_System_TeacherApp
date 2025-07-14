// lib/controllers/student_permission_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Import for Get.snackbar, Colors
import 'package:school_management_system_teacher_app/models/permission_item.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';

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

  @override
  void onInit() {
    super.onInit();
    // Pre-fetch all students when controller initializes
    _studentRepository.fetchAllStudents().then((_) {
      fetchStudentPermissions(); // Then fetch permissions
    }).catchError((e) {
      errorMessage.value = "Failed to load student data: ${e.toString().replaceFirst('Exception: ', '')}";
      isLoading.value = false;
      print('Error pre-fetching all students: $e');
    });
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
    print('--- PERMISSION COUNTS UPDATED ---');
    print('Total: ${totalPermissions.value}, Pending: ${pendingPermissions.value}, Approved: ${approvedPermissions.value}, Denied: ${deniedPermissions.value}');
    print('-------------------------------');
  }

  /// Fetches all relevant student permissions and enriches them with student details.
  Future<void> fetchStudentPermissions() async {
    isLoading.value = true;
    errorMessage.value = ''; // Clear any previous error
    print('Fetching student permissions...');

    try {
      final teacherStaffId = await _authController.getStaffId();
      if (teacherStaffId.isEmpty) {
        errorMessage.value = "Teacher Staff ID not found. Please log in.";
        isLoading.value = false;
        print('Error: Teacher Staff ID is empty.');
        return;
      }
      print('Teacher Staff ID: $teacherStaffId');

      // 1. Fetch all permission requests
      final List<PermissionItem> allPermissions =
          await _permissionService.fetchAllPermissions();
      print('Fetched ${allPermissions.length} raw permissions.');

      // 2. Filter permissions relevant to this teacher (sent_to matches teacherStaffId)
      final List<PermissionItem> filteredPermissions = allPermissions
          .where((p) => p.sentToStaffId == teacherStaffId)
          .toList();
      print('Filtered to ${filteredPermissions.length} permissions for this teacher.');

      if (filteredPermissions.isEmpty) {
        studentPermissions.assignAll([]); // Clear list if no permissions found
        _updatePermissionCounts(); // Update counts even if empty
        isLoading.value = false;
        print('No permissions found for this teacher.');
        return;
      }

      // 3. Enrich filtered permissions with student details using StudentRepository
      final List<PermissionItem> enrichedPermissions = [];
      for (var permission in filteredPermissions) {
        final Student? student = await _studentRepository.getStudentById(permission.studentId);
        if (student != null) {
          enrichedPermissions.add(permission.copyWith(studentDetails: student));
          print('  Permission ID: ${permission.id} - Student details found: ${student.engName} (ID: ${student.id})');
        } else {
          // If student details are not found, still add the permission but with null studentDetails
          enrichedPermissions.add(permission.copyWith(studentDetails: null));
          print('  Permission ID: ${permission.id} - Student details NOT FOUND in repository for ID: ${permission.studentId}');
        }
      }

      studentPermissions.assignAll(enrichedPermissions);
      _updatePermissionCounts(); // Update counts after data is loaded
      print('Finished enriching permissions. Total permissions in RxList: ${studentPermissions.length}');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print('!!! ERROR in fetchStudentPermissions: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates the status of a specific permission and refreshes the list.
  Future<void> updatePermissionStatus(
      String permissionId, String newStatus, String classId) async {
    print('Attempting to update permission status for $permissionId to $newStatus');
    try {
      await _permissionService.updatePermissionStatus(permissionId, newStatus);

      final index = studentPermissions.indexWhere((p) => p.id == permissionId);
      if (index != -1) {
        studentPermissions[index] =
            studentPermissions[index].copyWith(status: newStatus.toLowerCase());
        _updatePermissionCounts(); // Recalculate counts after status change
        print('Permission $permissionId status updated to $newStatus locally and counts recalculated.');
      }

      Get.snackbar(
        'Success',
        'Permission ${newStatus.capitalizeFirst}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successGreen,
        colorText: Colors.white,
      );
    } catch (e) {
      print('!!! ERROR updating permission status: ${e.toString()}');
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
