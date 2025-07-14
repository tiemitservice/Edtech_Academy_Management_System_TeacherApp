// tiemitservice/edtech_academy_management_system_teacherapp/Edtech_Academy_Management_System_TeacherApp-a41b5c2bda2f109f4f2f39b45e2ddf1ef6a9d71c/lib/controllers/student_list_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For Get.snackbar, Colors
import 'package:school_management_system_teacher_app/models/student.dart'; // Correctly import Student model
import 'package:school_management_system_teacher_app/services/student_list_service.dart';
import 'package:school_management_system_teacher_app/utils/app_colors.dart';

class StudentListController extends GetxController {
  final StudentListService _studentListService = Get.find<StudentListService>();

  final RxList<Student> students = <Student>[].obs; //
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final String? classId; // NEW: Field to hold the class ID

  StudentListController({this.classId}); // NEW: Constructor to accept classId

  @override
  void onInit() {
    super.onInit();
    fetchStudents(classId: classId); // Pass the classId to fetchStudents
  }

  /// Fetches the list of students from the service.
  /// If classId is provided, fetches students for that class.
  /// Otherwise, fetches all students.
  Future<void> fetchStudents({String? classId}) async { // Modified to accept classId
    isLoading.value = true;
    errorMessage.value = ''; // Clear previous error

    try {
      // Pass classId to service, which will filter students
      final fetchedStudents = await _studentListService.fetchAllStudents(classId: classId);
      students.assignAll(fetchedStudents); //
      print('Fetched ${students.length} students successfully for class $classId.');
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