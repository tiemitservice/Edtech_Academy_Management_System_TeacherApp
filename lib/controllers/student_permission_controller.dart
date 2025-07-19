// lib/controllers/student_permission_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';
import 'package:school_management_system_teacher_app/models/permission_item.dart';
import 'package:school_management_system_teacher_app/models/permission_report.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_permission_service.dart';
import 'package:school_management_system_teacher_app/services/student_repository.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:flutter/foundation.dart';

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
    _studentRepository.fetchAllStudents().then((_) {
      fetchStudentPermissions();
    }).catchError((e) {
      errorMessage.value = "Failed to load student data: ${e.toString().replaceFirst('Exception: ', '')}";
      isLoading.value = false;
    });
  }

  void _updatePermissionCounts() {
    totalPermissions.value = studentPermissions.length;
    pendingPermissions.value = studentPermissions
        .where((p) => p.status.toLowerCase() == 'pending')
        .length;
    approvedPermissions.value = studentPermissions
        .where((p) => p.status.toLowerCase() == 'approved')
        .length;
    deniedPermissions.value = studentPermissions
        .where((p) =>
            p.status.toLowerCase() == 'denied' ||
            p.status.toLowerCase() == 'rejected')
        .length;
  }

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
      final filteredPermissions = allPermissions
          .where((p) => p.sentToStaffId == teacherStaffId)
          .toList();

      final List<PermissionItem> enrichedPermissions = [];
      for (var permission in filteredPermissions) {
        final Student? student =
            await _studentRepository.getStudentById(permission.studentId);
        enrichedPermissions.add(permission.copyWith(studentDetails: student));
      }
      studentPermissions.assignAll(enrichedPermissions);
      _updatePermissionCounts();
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
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
      // Step 1: Update the original permission status
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
          // The main action (updating status) was successful.
          debugPrint('!!! FAILED to create permission report: $e');
        }
      }

      // Step 3: Update the local UI for immediate feedback
      final index = studentPermissions.indexWhere((p) => p.id == permission.id);
      if (index != -1) {
        studentPermissions[index] =
            studentPermissions[index].copyWith(status: newStatus.toLowerCase());
        _updatePermissionCounts(); // Recalculate counts
      }

      Get.snackbar(
        'Success',
        'Permission ${newStatus.capitalizeFirst}!',
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
