// lib/controllers/student_list_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For Get.snackbar, Colors
import 'package:school_management_system_teacher_app/models/student.dart'; // Correctly import Student model
import 'package:school_management_system_teacher_app/services/student_list_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';

class StudentListController extends GetxController {
  final StudentListService _studentListService = Get.find<StudentListService>();

  final RxList<Student> students = <Student>[].obs; // <--- THIS IS THE CORRECT NAME
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStudents();
  }

  /// Fetches the list of students from the service.
  Future<void> fetchStudents() async {
    isLoading.value = true;
    errorMessage.value = ''; // Clear previous error

    try {
      final fetchedStudents = await _studentListService.fetchAllStudents();
      students.assignAll(fetchedStudents);
      print('Fetched ${students.length} students successfully.');
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
