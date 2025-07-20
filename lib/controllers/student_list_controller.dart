// lib/controllers/student_list_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system_teacher_app/models/student.dart';
import 'package:school_management_system_teacher_app/services/student_list_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';
import 'package:school_management_system_teacher_app/controllers/auth_controller.dart';

class StudentListController extends GetxController {
  final StudentListService _studentListService = Get.find<StudentListService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Student> students = <Student>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxInt totalStudentsCount = 0.obs;

  final String classId;

  StudentListController({required this.classId});

  @override
  void onInit() {
    super.onInit();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    isLoading.value = true;
    errorMessage.value = '';
    totalStudentsCount.value = 0;
    students.clear();

    try {
      final staffId = await _authController.getStaffId();

      if (staffId.isEmpty) {
        errorMessage.value = "Teacher Staff ID not found. Please log in again.";
        Get.snackbar(
          'Authentication Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.declineRed,
          colorText: Colors.white,
        );
        return;
      }

      final result = await _studentListService.fetchStudentsForClass(
        classId: this.classId,
        staffId: staffId,
      );

      students.assignAll(result.students);
      totalStudentsCount.value = result.totalStudentsCount;

      print('Fetched ${students.length} students successfully for class ${this.classId}. Total items: ${totalStudentsCount.value}');
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching students: ${errorMessage.value}');
      Get.snackbar(
        'Error',
        'Failed to load students: ${errorMessage.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.declineRed,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}